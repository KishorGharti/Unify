import axios from 'axios';
import { env } from '../config/env';

// Thin wrapper around Meta's *standalone* Instagram Login product - a
// separate integration from meta.service.ts's Facebook-Login + linked-Page
// flow. No Facebook Page is involved: the business logs into Instagram
// directly, and every call here hits graph.instagram.com / api.instagram.com
// instead of graph.facebook.com. See backend/README.md for how the two paths
// fit together.

const IG_GRAPH_VERSION = 'v21.0';
const igGraph = axios.create({ baseURL: `https://graph.instagram.com/${IG_GRAPH_VERSION}`, timeout: 15000 });

export interface InstagramTokenExchangeResult {
  accessToken: string;
  expiresInSeconds: number | null;
}

export interface InstagramProfile {
  id: string;
  username: string;
  name?: string;
  profile_picture_url?: string;
}

/** Step 1: the Instagram Login dialog URL for the Flutter client to open. */
export function buildInstagramLoginUrl(state: string): string {
  const url = new URL('https://www.instagram.com/oauth/authorize');
  url.searchParams.set('client_id', env.metaInstagramLogin.appId);
  url.searchParams.set('redirect_uri', env.metaInstagramLogin.oauthRedirectUri);
  url.searchParams.set('state', state);
  url.searchParams.set('scope', 'instagram_business_basic,instagram_business_manage_messages');
  url.searchParams.set('response_type', 'code');
  return url.toString();
}

/** Step 2: exchange the redirect `code` for a short-lived token + the IG-scoped user id. */
export async function exchangeInstagramCode(code: string): Promise<{ accessToken: string; igUserId: string }> {
  const params = new URLSearchParams({
    client_id: env.metaInstagramLogin.appId,
    client_secret: env.metaInstagramLogin.appSecret,
    grant_type: 'authorization_code',
    redirect_uri: env.metaInstagramLogin.oauthRedirectUri,
    code,
  });
  const { data } = await axios.post('https://api.instagram.com/oauth/access_token', params, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });
  return { accessToken: data.access_token, igUserId: String(data.user_id) };
}

/** Step 3: exchange the short-lived token for a long-lived one (~60 days, refreshable). */
export async function exchangeForLongLivedInstagramToken(shortLivedToken: string): Promise<InstagramTokenExchangeResult> {
  // Unversioned endpoint per Meta's docs - a plain request, not through the
  // versioned `igGraph` client above.
  const { data } = await axios.get('https://graph.instagram.com/access_token', {
    params: {
      grant_type: 'ig_exchange_token',
      client_secret: env.metaInstagramLogin.appSecret,
      access_token: shortLivedToken,
    },
  });
  return { accessToken: data.access_token, expiresInSeconds: data.expires_in ?? null };
}

/**
 * Step 4: basic profile for the account that just logged in. Deliberately
 * uses `/me`, not `/{user_id}` with the id the code exchange returned - that
 * id is a different (Basic-Display-era) scheme and 400s against the Graph
 * API ("Unsupported get request... does not exist"). `/me` resolves
 * correctly from the token alone, and its `id` field is the one every other
 * call (webhook subscribe, send message, DB externalId) must use from here on.
 */
export async function fetchInstagramProfile(accessToken: string): Promise<InstagramProfile> {
  const { data } = await igGraph.get('/me', {
    params: { fields: 'id,username,name,profile_picture_url', access_token: accessToken },
  });
  return data as InstagramProfile;
}

/**
 * `/me`'s `id` field is an "Instagram-scoped ID" that does NOT match the id
 * Meta actually sends as `entry.id` on incoming webhooks - that one uses the
 * classic Instagram Business Account ID format instead (the same one the
 * Facebook-Page-linked flow already uses). Meta doesn't expose it as a plain
 * field on `/me`, but it reliably shows up embedded in the pagination URL of
 * `/me/conversations` - even with zero conversations. Verified interchangeable
 * with `/me`'s id for every other operation (subscribe, send), so this is
 * the one actually stored as Channel.externalId.
 */
export async function fetchInstagramWebhookId(accessToken: string): Promise<string | null> {
  const { data } = await igGraph.get('/me/conversations', { params: { access_token: accessToken } });
  const nextUrl: string | undefined = data?.paging?.next;
  const match = nextUrl?.match(/\/(\d+)\/conversations/);
  return match ? match[1] : null;
}

/** Step 5: subscribe this app to the account's message webhooks. */
export async function subscribeInstagramLoginWebhooks(igUserId: string, accessToken: string): Promise<void> {
  await igGraph.post(`/${igUserId}/subscribed_apps`, null, {
    params: { subscribed_fields: 'messages', access_token: accessToken },
  });
}

/** Sends a text message back to a customer via standalone Instagram Login. */
export async function sendInstagramLoginMessage(params: {
  igUserId: string;
  accessToken: string;
  recipientId: string; // IGSID
  text: string;
}): Promise<{ message_id: string }> {
  const { data } = await igGraph.post(
    `/${params.igUserId}/messages`,
    { recipient: { id: params.recipientId }, message: { text: params.text } },
    { params: { access_token: params.accessToken } },
  );
  return data;
}
