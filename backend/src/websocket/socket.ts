import { Server as HttpServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';

let io: SocketIOServer | null = null;

// Event shape mirrors SocketEvent.fromJson in lib/core/websocket/socket_events.dart:
// { event, tenant_id, conversation_id, payload, timestamp }
export interface OutgoingSocketEvent {
  event:
    | 'message.new'
    | 'message.status'
    | 'conversation.assigned'
    | 'conversation.status'
    | 'conversation.tags'
    | 'customer.typing'
    | 'channel.status';
  tenantId: string;
  conversationId?: string | null;
  payload: Record<string, unknown>;
}

export function initSocketServer(httpServer: HttpServer): SocketIOServer {
  io = new SocketIOServer(httpServer, {
    cors: { origin: env.corsOrigin, credentials: true },
  });

  // Flutter's real client (once AlgoraWebSocketService is implemented with
  // socket_io_client) should connect with `auth: { token }`, mirroring the
  // Bearer JWT used for REST calls, then get placed in a room scoped to its
  // tenant so it only ever receives its own workspace's events.
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) return next(new Error('Missing auth token.'));
    try {
      const payload = jwt.verify(token, env.jwtSecret) as { tenantId: string };
      socket.data.tenantId = payload.tenantId;
      next();
    } catch {
      next(new Error('Invalid or expired token.'));
    }
  });

  io.on('connection', (socket) => {
    const tenantId = socket.data.tenantId as string;
    socket.join(`tenant:${tenantId}`);

    socket.on('subscribe_conversation', (conversationId: string) => {
      socket.join(`conversation:${conversationId}`);
    });
    socket.on('unsubscribe_conversation', (conversationId: string) => {
      socket.leave(`conversation:${conversationId}`);
    });
  });

  return io;
}

/** Pushes a real-time event to every connected client in a tenant's workspace. */
export function emitToTenant(event: OutgoingSocketEvent): void {
  if (!io) return;
  io.to(`tenant:${event.tenantId}`).emit('algora_event', {
    event: event.event,
    tenant_id: event.tenantId,
    conversation_id: event.conversationId ?? null,
    payload: event.payload,
    timestamp: new Date().toISOString(),
  });
}
