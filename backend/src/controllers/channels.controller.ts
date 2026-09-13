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
import {
  buildInstagramLoginUrl,
  exchangeInstagramCode,
  exchangeForLongLivedInstagramToken,
  fetchInstagramProfile,
  fetchInstagramWebhookId,
  subscribeInstagramLoginWebhooks,
} from '../services/instagramLogin.service';
import {
  setPendingPages,
  getPendingPages,
  clearPendingPages,
  setPendingInstagramLogin,
  getPendingInstagramLogin,
  clearPendingInstagramLogin,
} from '../services/pendingConnections.store';

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

export async function getConnectedAccounts(req: AuthedRequest, res: Response) {
  const channels = await prisma.channel.findMany({
    where: { tenantId: req.tenantId },
    include: { _count: { select: { conversations: true } } },
    orderBy: { connectedAt: 'desc' },
  });
  return ok(res, channels.map((c) => toConnectedAccountJson(c, c._count.conversations)));
}

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

  return res.send(`
    <html><body style="font-family:sans-serif;text-align:center;padding-top:4rem;">
      <h2>Facebook connected ✅</h2>
      <p>Found ${pages.length} Page(s). Return to the Unify app to finish selecting one.</p>
    </body></html>
  `);
}

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
      username: `@${p.name.toLowerCase().replace(/\s+/g, '.')}`,
      name: p.name,
      followers_count: 0,
      linked_page: p.name,
      is_connected: connectedExternalIds.has(p.instagram_business_account!.id),
      _linkedPageId: p.id,
    }));
  return ok(res, igAccounts);
}

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

export async function startInstagramLoginOAuth(req: AuthedRequest, res: Response) {
  env.assertInstagramLoginConfigured();

  const state = jwt.sign({ tenantId: req.tenantId }, env.jwtSecret, { expiresIn: '10m' });
  return ok(res, { oauth_url: buildInstagramLoginUrl(state) });
}

export async function instagramLoginOAuthCallback(req: AuthedRequest, res: Response) {
  const { code, state, error, error_description } = req.query as Record<string, string>;

  if (error) {
    return res.status(400).send(`<h3>Instagram login failed</h3><p>${error_description ?? error}</p>`);
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

  const shortLived = await exchangeInstagramCode(code);
  const longLived = await exchangeForLongLivedInstagramToken(shortLived.accessToken);

  const profile = await fetchInstagramProfile(longLived.accessToken);

  const webhookId = await fetchInstagramWebhookId(longLived.accessToken);
  setPendingInstagramLogin(tenantId, {
    ...profile,
    id: webhookId ?? profile.id,
    accessToken: longLived.accessToken,
  });

  return res.send(`
    <html><body style="font-family:sans-serif;text-align:center;padding-top:4rem;">
      <h2>Instagram connected ✅</h2>
      <p>Found @${profile.username}. Return to the Unify app to finish connecting it.</p>
    </body></html>
  `);
}

export async function listInstagramLoginAccounts(req: AuthedRequest, res: Response) {
  const account = getPendingInstagramLogin(req.tenantId!);
  if (!account) {
    return fail(res, 'No pending Instagram Login connection. Start the login flow first.', 409);
  }
  const connectedExternalIds = new Set(
    (await prisma.channel.findMany({ where: { tenantId: req.tenantId, channelType: 'instagram' }, select: { externalId: true } })).map(
      (c) => c.externalId,
    ),
  );
  return ok(res, [
    {
      id: account.id,
      username: `@${account.username}`,
      name: account.name ?? account.username,
      followers_count: 0,
      linked_page: null,
      is_connected: connectedExternalIds.has(account.id),
    },
  ]);
}

export async function connectInstagramLoginAccount(req: AuthedRequest, res: Response) {
  const { ig_user_id } = req.body ?? {};
  if (!ig_user_id) return fail(res, 'ig_user_id is required.', 422);

  const account = getPendingInstagramLogin(req.tenantId!);
  if (!account || account.id !== ig_user_id) {
    return fail(res, 'Unknown ig_user_id, or the login session expired. Restart the connection flow.', 409);
  }

  await subscribeInstagramLoginWebhooks(account.id, account.accessToken);

  const channel = await prisma.channel.upsert({
    where: { channelType_externalId: { channelType: 'instagram', externalId: account.id } },
    update: {
      accountName: `@${account.username}`,
      status: 'active',
      authMethod: 'instagram_login',
      accessTokenEncrypted: encryptToken(account.accessToken),
    },
    create: {
      tenantId: req.tenantId!,
      channelType: 'instagram',
      authMethod: 'instagram_login',
      accountName: `@${account.username}`,
      externalId: account.id,
      status: 'active',
      accessTokenEncrypted: encryptToken(account.accessToken),
      permissionsGranted: JSON.stringify(['instagram_business_basic', 'instagram_business_manage_messages']),
    },
  });

  clearPendingInstagramLogin(req.tenantId!);
  return ok(res, toConnectedAccountJson(channel, 0), 201);
}

export async function disconnectChannel(req: AuthedRequest, res: Response) {
  const { id } = req.params;
  const channel = await prisma.channel.findFirst({ where: { id, tenantId: req.tenantId } });
  if (!channel) return fail(res, 'Channel not found.', 404);

  await prisma.channel.delete({ where: { id } });
  clearPendingPages(req.tenantId!);
  return ok(res, { disconnected: true });
}

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
