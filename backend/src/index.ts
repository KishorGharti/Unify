import express, { Request } from 'express';
import cors from 'cors';
import path from 'path';
import { createServer } from 'http';
import { env } from './config/env';
import { initSocketServer } from './websocket/socket';
import { notFoundHandler, errorHandler } from './middleware/errorHandler';

import authRoutes from './routes/auth.routes';
import channelsRoutes from './routes/channels.routes';
import webhooksRoutes from './routes/webhooks.routes';
import inboxRoutes from './routes/inbox.routes';
import analyticsRoutes from './routes/analytics.routes';
import adminApiRoutes from './routes/admin.routes';

interface RawBodyRequest extends Request {
  rawBody?: Buffer;
}

const app = express();

app.use(cors({ origin: env.corsOrigin }));
// Captures the raw request bytes (needed to verify Meta's X-Hub-Signature-256
// HMAC on webhook POSTs) while still parsing JSON for every route.
app.use(
  express.json({
    verify: (req: RawBodyRequest, _res, buf) => {
      req.rawBody = Buffer.from(buf);
    },
  }),
);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// Mounted to match ApiEndpoints.baseUrl = 'https://api.unify.io/v1' in
// lib/core/constants/api_endpoints.dart - point the Flutter app's baseUrl at
// http://<this-host>:{PORT}/api/v1 (or your deployed URL) during development.
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/channels', channelsRoutes);
app.use('/api/v1/inbox', inboxRoutes);
app.use('/api/v1/analytics', analyticsRoutes);

// Meta calls this directly - not under /api/v1, and not tenant-scoped.
app.use('/webhooks', webhooksRoutes);

// Separate admin panel: its own JSON API (own JWT, own auth middleware - see
// middleware/adminAuth.ts) plus the static page that calls it, both isolated
// from the tenant-facing /api/v1 surface above.
app.use('/api/admin', adminApiRoutes);
app.use('/admin', express.static(path.join(__dirname, '..', 'public', 'admin')));

app.use(notFoundHandler);
app.use(errorHandler);

const httpServer = createServer(app);
initSocketServer(httpServer);

httpServer.listen(env.port, () => {
  console.log(`Unify backend listening on http://localhost:${env.port}`);
  console.log(`Webhook callback URL to register with Meta: <public-url>/webhooks/meta`);
});
