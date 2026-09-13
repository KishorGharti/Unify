import { Response } from 'express';
import { prisma } from '../db/prisma';
import { AuthedRequest } from '../middleware/auth';
import { ok, fail } from '../utils/apiResponse';
import { decryptToken } from '../utils/crypto';
import { sendMetaMessage } from '../services/meta.service';
import { sendInstagramLoginMessage } from '../services/instagramLogin.service';
import { emitToTenant } from '../websocket/socket';

function toCustomerJson(conversation: { customerExternalId: string; customerName: string | null; customerAvatarUrl: string | null; createdAt: Date; lastMessageAt: Date | null }, channelType: string) {
  return {
    id: conversation.customerExternalId,
    full_name: conversation.customerName ?? `Customer ${conversation.customerExternalId.slice(-6)}`,
    email: null,
    phone: null,
    avatar_url: conversation.customerAvatarUrl,
    primary_channel: channelType,
    social_handle: conversation.customerExternalId,
    location: null,
    notes: null,
    tags: [],
    total_conversations_count: 1,
    total_spend: 0,
    first_seen_at: conversation.createdAt.toISOString(),
    last_active_at: (conversation.lastMessageAt ?? conversation.createdAt).toISOString(),
  };
}

function toMessageJson(message: {
  id: string;
  conversationId: string;
  direction: string;
  senderType: string;
  senderAgent: { fullName: string } | null;
  text: string | null;
  attachmentUrl: string | null;
  isInternalNote: boolean;
  createdAt: Date;
}, channelType: string) {
  return {
    id: message.id,
    conversation_id: message.conversationId,
    sender_type: message.isInternalNote ? 'agent' : message.senderType,
    sender_name: message.senderAgent?.fullName ?? (message.senderType === 'customer' ? 'Customer' : 'Agent'),
    sender_avatar_url: null,
    message_type: message.isInternalNote ? 'internal_note' : message.attachmentUrl ? 'image' : 'text',
    text: message.text ?? '',
    media_url: message.attachmentUrl,
    file_name: null,
    file_size: null,
    channel: channelType,
    status: message.direction === 'outbound' ? 'sent' : 'delivered',
    created_at: message.createdAt.toISOString(),
  };
}

async function toConversationJson(conversation: {
  id: string;
  tenantId: string;
  customerExternalId: string;
  customerName: string | null;
  customerAvatarUrl: string | null;
  status: string;
  tags: string;
  assignedAgentId: string | null;
  assignedAgent: { fullName: string } | null;
  createdAt: Date;
  lastMessageAt: Date | null;
  channel: { channelType: string };
  messages: Array<Parameters<typeof toMessageJson>[0]>;
}) {
  const latest = conversation.messages[conversation.messages.length - 1];
  return {
    id: conversation.id,
    tenant_id: conversation.tenantId,
    customer: toCustomerJson(conversation, conversation.channel.channelType),
    channel: conversation.channel.channelType,
    latest_message_text: latest?.text ?? '',
    latest_message_timestamp: (latest?.createdAt ?? conversation.createdAt).toISOString(),
    unread_count: 0,
    is_read: true,
    assigned_to_member_id: conversation.assignedAgentId,
    assigned_to_member_name: conversation.assignedAgent?.fullName ?? null,
    status: conversation.status,
    tags: JSON.parse(conversation.tags) as string[],
    recent_messages: conversation.messages.map((m) => toMessageJson(m, conversation.channel.channelType)),
  };
}

const conversationInclude = {
  channel: true,
  assignedAgent: true,
  messages: { orderBy: { createdAt: 'asc' as const }, include: { senderAgent: true } },
};

export async function getConversations(req: AuthedRequest, res: Response) {
  const conversations = await prisma.conversation.findMany({
    where: { tenantId: req.tenantId },
    include: conversationInclude,
    orderBy: { lastMessageAt: 'desc' },
  });
  return ok(res, await Promise.all(conversations.map(toConversationJson)));
}

export async function getConversationById(req: AuthedRequest, res: Response) {
  const conversation = await prisma.conversation.findFirst({
    where: { id: req.params.id, tenantId: req.tenantId },
    include: conversationInclude,
  });
  if (!conversation) return fail(res, 'Conversation not found.', 404);
  return ok(res, await toConversationJson(conversation));
}

export async function getMessages(req: AuthedRequest, res: Response) {
  const conversation = await prisma.conversation.findFirst({
    where: { id: req.params.id, tenantId: req.tenantId },
    include: { channel: true },
  });
  if (!conversation) return fail(res, 'Conversation not found.', 404);

  const messages = await prisma.message.findMany({
    where: { conversationId: conversation.id },
    orderBy: { createdAt: 'asc' },
    include: { senderAgent: true },
  });
  return ok(res, messages.map((m) => toMessageJson(m, conversation.channel.channelType)));
}

export async function sendMessage(req: AuthedRequest, res: Response) {
  const { text } = req.body ?? {};
  if (!text) return fail(res, 'text is required.', 422);

  const conversation = await prisma.conversation.findFirst({
    where: { id: req.params.id, tenantId: req.tenantId },
    include: { channel: true },
  });
  if (!conversation) return fail(res, 'Conversation not found.', 404);

  const accessToken = decryptToken(conversation.channel.accessTokenEncrypted);

  const metaResult =
    conversation.channel.authMethod === 'instagram_login'
      ? await sendInstagramLoginMessage({
          igUserId: conversation.channel.externalId,
          accessToken,
          recipientId: conversation.customerExternalId,
          text,
        })
      : await sendMetaMessage({
          pageId: conversation.channel.externalId,
          pageAccessToken: accessToken,
          recipientId: conversation.customerExternalId,
          text,
        });

  const agent = await prisma.user.findUnique({ where: { id: req.userId } });
  const message = await prisma.message.create({
    data: {
      conversationId: conversation.id,
      direction: 'outbound',
      senderType: 'agent',
      senderAgentId: req.userId,
      text,
      metaMessageId: metaResult.message_id,
    },
  });
  await prisma.conversation.update({ where: { id: conversation.id }, data: { lastMessageAt: new Date() } });

  const messageJson = toMessageJson({ ...message, senderAgent: agent }, conversation.channel.channelType);
  emitToTenant({ event: 'message.new', tenantId: req.tenantId!, conversationId: conversation.id, payload: messageJson });
  return ok(res, messageJson, 201);
}

export async function addInternalNote(req: AuthedRequest, res: Response) {
  const { text } = req.body ?? {};
  if (!text) return fail(res, 'text is required.', 422);

  const conversation = await prisma.conversation.findFirst({
    where: { id: req.params.id, tenantId: req.tenantId },
    include: { channel: true },
  });
  if (!conversation) return fail(res, 'Conversation not found.', 404);

  const agent = await prisma.user.findUnique({ where: { id: req.userId } });
  const message = await prisma.message.create({
    data: {
      conversationId: conversation.id,
      direction: 'outbound',
      senderType: 'agent',
      senderAgentId: req.userId,
      text,
      isInternalNote: true,
    },
  });

  const messageJson = toMessageJson({ ...message, senderAgent: agent }, conversation.channel.channelType);
  emitToTenant({ event: 'message.new', tenantId: req.tenantId!, conversationId: conversation.id, payload: messageJson });
  return ok(res, messageJson, 201);
}

export async function assignConversation(req: AuthedRequest, res: Response) {
  const { member_id } = req.body ?? {};
  const conversation = await prisma.conversation.findFirst({ where: { id: req.params.id, tenantId: req.tenantId } });
  if (!conversation) return fail(res, 'Conversation not found.', 404);

  await prisma.conversation.update({ where: { id: conversation.id }, data: { assignedAgentId: member_id ?? null } });
  emitToTenant({ event: 'conversation.assigned', tenantId: req.tenantId!, conversationId: conversation.id, payload: { member_id: member_id ?? null } });
  return ok(res, { assigned: true });
}

export async function updateStatus(req: AuthedRequest, res: Response) {
  const { status } = req.body ?? {};
  if (!['open', 'pending', 'resolved'].includes(status)) return fail(res, 'status must be open, pending, or resolved.', 422);

  const conversation = await prisma.conversation.findFirst({ where: { id: req.params.id, tenantId: req.tenantId } });
  if (!conversation) return fail(res, 'Conversation not found.', 404);

  await prisma.conversation.update({ where: { id: conversation.id }, data: { status } });
  emitToTenant({ event: 'conversation.status', tenantId: req.tenantId!, conversationId: conversation.id, payload: { status } });
  return ok(res, { status });
}

export async function updateTags(req: AuthedRequest, res: Response) {
  const { tags } = req.body ?? {};
  if (!Array.isArray(tags)) return fail(res, 'tags must be an array of strings.', 422);

  const conversation = await prisma.conversation.findFirst({ where: { id: req.params.id, tenantId: req.tenantId } });
  if (!conversation) return fail(res, 'Conversation not found.', 404);

  await prisma.conversation.update({ where: { id: conversation.id }, data: { tags: JSON.stringify(tags) } });
  emitToTenant({ event: 'conversation.tags', tenantId: req.tenantId!, conversationId: conversation.id, payload: { tags } });
  return ok(res, { tags });
}
