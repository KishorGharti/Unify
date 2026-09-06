import { Response } from 'express';
import jwt from 'jsonwebtoken';
import { prisma } from '../db/prisma';
import { env } from '../config/env';
import { AuthedRequest } from '../middleware/auth';
import { ok, fail } from '../utils/apiResponse';
import { encryptToken } from '../utils/crypto';
import {
  exchangeCodeForUserToken,
  exchangeForLongLivedUserToken,
  fetchManagedPages,
  subscribePageToWebhooks,
} from '../services/meta.service';
import { setPendingPages, getPendingPages, clearPendingPages } from '../services/pendingConnections.store';

function toConnectedAccountJson(channel: {
  id: string;
  tenantId: string;
  channelType: string;
  accountName: string;
  externalId: string;
  status: string;
  lastWebhookReceived: Date | null;
  permissionsGranted: string;
  connectedAt: Date;
}, activeConversationsCount: number) {
  return {
    id: channel.id,
    tenant_id: channel.tenantId,
    channel_type: channel.channelType,
    account_name: channel.accountName,
    external_id: channel.externalId,
    profile_pic_url: null,
    status: channel.status,
    active_conversations_count: activeConversationsCount,
    last_webhook_received: (channel.lastWebhookReceived ?? channel.connectedAt).toISOString(),
    permissions_granted: JSON.parse(channel.permissionsGranted) as string[],
    connected_at: channel.connectedAt.toISOString(),
  };
}

// GET /channels - list this tenant's connected Facebook/Instagram accounts.
export async function getConnectedAccounts(req: AuthedRequest, res: Response) {
  const channels = await prisma.channel.findMany({
    where: { tenantId: req.tenantId },
    include: { _count: { select: { conversations: true } } },
    orderBy: { connectedAt: 'desc' },
  });
  return ok(res, channels.map((c) => toConnectedAccountJson(c, c._count.conversations)));
}

// GET /channels/meta/oauth/start - builds the Meta Login dialog URL for the
// Flutter client to open in a webview/browser (replaces the fake
// `Future.delayed` in connect_facebook_screen.dart's _startOAuthFlow).
export async function startOAuth(req: AuthedRequest, res: Response) {
  env.assertMetaConfigured();

  const state = jwt.sign({ tenantId: req.tenantId }, env.jwtSecret, { expiresIn: '10m' });
  const scope = [
    'pages_show_list',
    'pages_messaging',
    'pages_manage_metadata',
    'pages_read_engagement',
    'instagram_basic',
    'instagram_manage_messages',
    'business_management',
  ].join(',');

  const url = new URL(`https://www.facebook.com/${env.meta.graphApiVersion}/dialog/oauth`);
  url.searchParams.set('client_id', env.meta.appId);
  url.searchParams.set('redirect_uri', env.meta.oauthRedirectUri);
  url.searchParams.set('state', state);
  url.searchParams.set('scope', scope);
  url.searchParams.set('response_type', 'code');

  return ok(res, { oauth_url: url.toString() });
}

// GET /channels/meta/oauth/callback - Meta redirects here after the user
// approves the login dialog. Must be publicly reachable (use ngrok locally)
// and must exactly match META_OAUTH_REDIRECT_URI + the dashboard's allow-list.
export async function oauthCallback(req: AuthedRequest, res: Response) {
  const { code, state, error, error_description } = req.query as Record<string, string>;

  if (error) {
    return res.status(400).send(`<h3>Facebook login failed</h3><p>${error_description ?? error}</p>`);
  }
  if (!code || !state) {
    return res.status(400).send('<h3>Missing code or state parameter.</h3>');
  }

  let tenantId: string;
  try {
    const payload = jwt.verify(state, env.jwtSecret) as { tenantId: string };
    tenantId = payload.tenantId;
  } catch {
    return res.status(400).send('<h3>Invalid or expired OAuth state. Please retry from the app.</h3>');
  }

  const shortLived = await exchangeCodeForUserToken(code);
  const longLived = await exchangeForLongLivedUserToken(shortLived.accessToken);
  const pages = await fetchManagedPages(longLived.accessToken);
  setPendingPages(tenantId, pages);

  // In production, redirect to a deep link your Flutter app registers, e.g.:
  //   res.redirect(`algora://oauth-complete?tenant_id=${tenantId}`);
  // so the app resumes the "select a Page" step automatically.
  return res.send(`
    <html><body style="font-family:sans-serif;text-align:center;padding-top:4rem;">
      <h2>Facebook connected ✅</h2>
      <p>Found ${pages.length} Page(s). Return to the Algora app to finish selecting one.</p>
    </body></html>
  `);
}

// GET /channels/meta/facebook/pages - Pages found in the most recent OAuth
// session for this tenant, shaped like the mock in channel_repository.dart.
export async function listFacebookPages(req: AuthedRequest, res: Response) {
  const pages = getPendingPages(req.tenantId!);
  if (!pages) {
    return fail(res, 'No pending Facebook connection. Start the OAuth flow first.', 409);
  }
  const connectedExternalIds = new Set(
    (await prisma.channel.findMany({ where: { tenantId: req.tenantId, channelType: 'facebook' }, select: { externalId: true } })).map(
      (c) => c.externalId,
    ),
  );
  return ok(
    res,
    pages.map((p) => ({
      id: p.id,
      name: p.name,
      category: p.category ?? null,
      fan_count: p.fan_count ?? 0,
      is_connected: connectedExternalIds.has(p.id),
    })),
  );
}

// GET /channels/meta/instagram/accounts - IG Professional accounts linked to
// Pages found in the most recent OAuth session for this tenant.
export async function listInstagramAccounts(req: AuthedRequest, res: Response) {
  const pages = getPendingPages(req.tenantId!);
  if (!pages) {
    return fail(res, 'No pending Instagram connection. Start the OAuth flow first.', 409);
  }
  const connectedExternalIds = new Set(
    (await prisma.channel.findMany({ where: { tenantId: req.tenantId, channelType: 'instagram' }, select: { externalId: true } })).map(
      (c) => c.externalId,
    ),
  );
  const igAccounts = pages
    .filter((p) => p.instagram_business_account)
    .map((p) => ({
      id: p.instagram_business_account!.id,
      username: `@${p.name.toLowerCase().replace(/\s+/g, '.')}`, // refined by a follow-up Graph call if you need the real handle
      name: p.name,
      followers_count: 0,
      linked_page: p.name,
      is_connected: connectedExternalIds.has(p.instagram_business_account!.id),
      _linkedPageId: p.id,
    }));
  return ok(res, igAccounts);
}

// POST /channels/meta/facebook/connect { page_id }
// Deliberately ignores any access token the client sends: the Page token
// only ever comes from the server-side OAuth exchange, never the app.
export async function connectFacebookPage(req: AuthedRequest, res: Response) {
  const { page_id } = req.body ?? {};
  if (!page_id) return fail(res, 'page_id is required.', 422);

  const pages = getPendingPages(req.tenantId!);
  const page = pages?.find((p) => p.id === page_id);
  if (!page) return fail(res, 'Unknown page_id, or the OAuth session expired. Restart the connection flow.', 409);

  await subscribePageToWebhooks(page.id, page.access_token);

  const channel = await prisma.channel.upsert({
    where: { channelType_externalId: { channelType: 'facebook', externalId: page.id } },
    update: {
      accountName: page.name,
      status: 'active',
      accessTokenEncrypted: encryptToken(page.access_token),
    },
    create: {
      tenantId: req.tenantId!,
      channelType: 'facebook',
      accountName: page.name,
      externalId: page.id,
      status: 'active',
      accessTokenEncrypted: encryptToken(page.access_token),
      permissionsGranted: JSON.stringify(['pages_messaging', 'pages_manage_metadata', 'pages_read_engagement']),
    },
  });

  return ok(res, toConnectedAccountJson(channel, 0), 201);
}

// POST /channels/meta/instagram/connect { ig_user_id, page_id }
// The IG business account is messaged through its linked Page's access token.
export async function connectInstagramAccount(req: AuthedRequest, res: Response) {
  const { ig_user_id, page_id } = req.body ?? {};
  if (!ig_user_id || !page_id) return fail(res, 'ig_user_id and page_id are required.', 422);

  const pages = getPendingPages(req.tenantId!);
  const page = pages?.find((p) => p.id === page_id && p.instagram_business_account?.id === ig_user_id);
  if (!page) return fail(res, 'Unknown ig_user_id/page_id, or the OAuth session expired. Restart the connection flow.', 409);

  await subscribePageToWebhooks(page.id, page.access_token);

  const channel = await prisma.channel.upsert({
    where: { channelType_externalId: { channelType: 'instagram', externalId: ig_user_id } },
    update: {
      accountName: `@${page.name.toLowerCase().replace(/\s+/g, '.')}`,
      status: 'active',
      accessTokenEncrypted: encryptToken(page.access_token),
    },
    create: {
      tenantId: req.tenantId!,
      channelType: 'instagram',
      accountName: `@${page.name.toLowerCase().replace(/\s+/g, '.')}`,
      externalId: ig_user_id,
      status: 'active',
      accessTokenEncrypted: encryptToken(page.access_token),
      permissionsGranted: JSON.stringify(['instagram_basic', 'instagram_manage_messages']),
    },
  });

  return ok(res, toConnectedAccountJson(channel, 0), 201);
}

// POST /channels/{id}/disconnect
export async function disconnectChannel(req: AuthedRequest, res: Response) {
  const { id } = req.params;
  const channel = await prisma.channel.findFirst({ where: { id, tenantId: req.tenantId } });
  if (!channel) return fail(res, 'Channel not found.', 404);

  await prisma.channel.delete({ where: { id } });
  clearPendingPages(req.tenantId!);
  return ok(res, { disconnected: true });
}

// GET /channels/{id}/health
export async function channelHealth(req: AuthedRequest, res: Response) {
  const { id } = req.params;
  const channel = await prisma.channel.findFirst({ where: { id, tenantId: req.tenantId } });
  if (!channel) return fail(res, 'Channel not found.', 404);

  return ok(res, {
    id: channel.id,
    status: channel.status,
    last_webhook_received: channel.lastWebhookReceived?.toISOString() ?? null,
  });
}
