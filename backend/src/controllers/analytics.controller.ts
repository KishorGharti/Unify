import { Response } from 'express';
import { prisma } from '../db/prisma';
import { AuthedRequest } from '../middleware/auth';
import { ok } from '../utils/apiResponse';

function formatDuration(ms: number): string {
  const totalSeconds = Math.round(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return minutes === 0 ? `${seconds}s` : `${minutes}m ${seconds}s`;
}

type ActivityMessage = {
  id: string;
  direction: string;
  isInternalNote: boolean;
  text: string | null;
  createdAt: Date;
  senderAgent: { fullName: string } | null;
  conversation: { customerName: string | null; channel: { channelType: string } };
};

function buildActivityTitle(m: ActivityMessage): string {
  const channelLabel = m.conversation.channel.channelType === 'instagram' ? 'Instagram DM' : 'Facebook Page';
  const customer = m.conversation.customerName ?? 'a customer';
  if (m.isInternalNote) return `Internal note by ${m.senderAgent?.fullName ?? 'an agent'}`;
  if (m.direction === 'inbound') return `${channelLabel} from ${customer}`;
  return `${channelLabel} reply by ${m.senderAgent?.fullName ?? 'an agent'}`;
}

// GET /analytics/dashboard - real numbers computed from this tenant's actual
// Conversations/Messages, not sample data. Everything here is derived, not
// stored directly, so it stays correct as messages come and go:
//   - resolved_today approximates "resolved" conversations by their last
//     activity falling today (Conversation has no resolvedAt column yet).
//   - avg_response_time is the mean gap between an inbound customer message
//     and the next outbound agent reply in the same conversation.
export async function getDashboardMetrics(req: AuthedRequest, res: Response) {
  const tenantId = req.tenantId!;

  const conversations = await prisma.conversation.findMany({
    where: { tenantId },
    include: { channel: true },
  });

  const totalConversations = conversations.length;
  const openConversations = conversations.filter((c) => c.status === 'open').length;
  const resolvedTotal = conversations.filter((c) => c.status === 'resolved').length;
  const resolutionRate = totalConversations > 0 ? Math.round((resolvedTotal / totalConversations) * 1000) / 10 : 0;

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);
  const resolvedToday = conversations.filter(
    (c) => c.status === 'resolved' && c.lastMessageAt !== null && c.lastMessageAt >= startOfToday,
  ).length;

  const facebookInquiries = conversations.filter((c) => c.channel.channelType === 'facebook').length;
  const instagramInquiries = conversations.filter((c) => c.channel.channelType === 'instagram').length;

  // Average first-response time across every conversation: gap between each
  // inbound message and the next outbound reply that follows it.
  const allMessages = await prisma.message.findMany({
    where: { conversation: { tenantId } },
    orderBy: [{ conversationId: 'asc' }, { createdAt: 'asc' }],
  });

  const responseTimesMs: number[] = [];
  let pendingInboundAt: Date | null = null;
  let lastConversationId: string | null = null;
  for (const m of allMessages) {
    if (m.conversationId !== lastConversationId) {
      pendingInboundAt = null;
      lastConversationId = m.conversationId;
    }
    if (m.direction === 'inbound') {
      pendingInboundAt = m.createdAt;
    } else if (m.direction === 'outbound' && !m.isInternalNote && pendingInboundAt) {
      responseTimesMs.push(m.createdAt.getTime() - pendingInboundAt.getTime());
      pendingInboundAt = null;
    }
  }
  const avgResponseTime =
    responseTimesMs.length > 0
      ? formatDuration(responseTimesMs.reduce((a, b) => a + b, 0) / responseTimesMs.length)
      : '—';

  const recentMessages = await prisma.message.findMany({
    where: { conversation: { tenantId } },
    orderBy: { createdAt: 'desc' },
    take: 6,
    include: { senderAgent: true, conversation: { include: { channel: true } } },
  });

  const recentActivities = recentMessages.map((m) => ({
    id: m.id,
    title: buildActivityTitle(m),
    description: (m.text ?? '').slice(0, 140),
    channel: m.conversation.channel.channelType,
    timestamp: m.createdAt.toISOString(),
  }));

  return ok(res, {
    total_conversations: totalConversations,
    open_conversations: openConversations,
    resolved_today: resolvedToday,
    avg_response_time: avgResponseTime,
    resolution_rate: resolutionRate,
    facebook_inquiries: facebookInquiries,
    instagram_inquiries: instagramInquiries,
    recent_activities: recentActivities,
  });
}
