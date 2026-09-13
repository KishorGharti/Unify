import { Request, Response } from 'express';
import { prisma } from '../db/prisma';
import { env } from '../config/env';
import { verifyMetaSignature } from '../utils/crypto';
import { emitToTenant } from '../websocket/socket';

interface RawBodyRequest extends Request {
  rawBody?: Buffer;
}

export function verifyWebhook(req: Request, res: Response) {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === env.meta.webhookVerifyToken) {
    return res.status(200).send(challenge);
  }
  return res.sendStatus(403);
}

export async function receiveWebhook(req: RawBodyRequest, res: Response) {
  const signatureOk = verifyMetaSignature(req.rawBody ?? Buffer.from(JSON.stringify(req.body)), req.header('X-Hub-Signature-256'));
  if (!signatureOk) {
    console.warn('Webhook signature verification failed - rejecting payload.');
    return res.sendStatus(401);
  }

  res.sendStatus(200);

  const body = req.body as {
    object: 'page' | 'instagram';
    entry: Array<{
      id: string;
      time: number;
      messaging?: Array<{
        sender: { id: string };
        recipient: { id: string };
        timestamp: number;
        message?: { mid: string; text?: string; attachments?: Array<{ payload: { url: string } }> };
      }>;
    }>;
  };

  const channelType = body.object === 'instagram' ? 'instagram' : 'facebook';

  for (const entry of body.entry ?? []) {
    const channel = await prisma.channel.findUnique({
      where: { channelType_externalId: { channelType, externalId: entry.id } },
    });
    if (!channel) {
      console.warn(`Webhook for unknown ${channelType} channel externalId=${entry.id} - ignoring.`);
      continue;
    }

    await prisma.channel.update({ where: { id: channel.id }, data: { lastWebhookReceived: new Date() } });

    for (const messaging of entry.messaging ?? []) {
      if (!messaging.message) continue;
      if (messaging.sender.id === entry.id) continue;

      const conversation = await prisma.conversation.upsert({
        where: { channelId_customerExternalId: { channelId: channel.id, customerExternalId: messaging.sender.id } },
        update: { lastMessageAt: new Date(messaging.timestamp) },
        create: {
          tenantId: channel.tenantId,
          channelId: channel.id,
          customerExternalId: messaging.sender.id,
          status: 'open',
          lastMessageAt: new Date(messaging.timestamp),
        },
      });

      const message = await prisma.message.create({
        data: {
          conversationId: conversation.id,
          direction: 'inbound',
          senderType: 'customer',
          text: messaging.message.text ?? '',
          attachmentUrl: messaging.message.attachments?.[0]?.payload.url ?? null,
          metaMessageId: messaging.message.mid,
        },
      });

      emitToTenant({
        event: 'message.new',
        tenantId: channel.tenantId,
        conversationId: conversation.id,
        payload: {
          id: message.id,
          conversation_id: conversation.id,
          sender_type: 'customer',
          sender_name: 'Customer',
          message_type: message.attachmentUrl ? 'image' : 'text',
          text: message.text,
          media_url: message.attachmentUrl,
          channel: channelType,
          status: 'delivered',
          created_at: message.createdAt.toISOString(),
        },
      });
    }
  }
}
