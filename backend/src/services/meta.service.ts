import axios from 'axios';
import { env } from '../config/env';

// Thin wrapper around the Meta Graph API for the calls the Facebook/Instagram
// Messaging integration needs. See backend/README.md for the end-to-end flow
// this supports.

const graph = axios.create({
  baseURL: `https://graph.facebook.com/${env.meta.graphApiVersion}`,
  timeout: 15000,
});

export interface MetaPage {
  id: string;
  name: string;
  category?: string;
  fan_count?: number;
  access_token: string; // Page access token (never expires unless revoked)
  instagram_business_account?: { id: string };
}

export interface MetaTokenExchangeResult {
  accessToken: string;
  expiresInSeconds: number | null; // null for the long-lived token (effectively non-expiring for Pages)
}

/** Step 1: exchange the OAuth `code` from the login redirect for a short-lived user token. */
export async function exchangeCodeForUserToken(code: string): Promise<MetaTokenExchangeResult> {
  const { data } = await graph.get('/oauth/access_token', {
    params: {
      client_id: env.meta.appId,
      client_secret: env.meta.appSecret,
      redirect_uri: env.meta.oauthRedirectUri,
      code,
    },
  });
  return { accessToken: data.access_token, expiresInSeconds: data.expires_in ?? null };
}

/** Step 2: exchange a short-lived user token for a long-lived one (~60 days). */
export async function exchangeForLongLivedUserToken(shortLivedToken: string): Promise<MetaTokenExchangeResult> {
  const { data } = await graph.get('/oauth/access_token', {
    params: {
      grant_type: 'fb_exchange_token',
      client_id: env.meta.appId,
      client_secret: env.meta.appSecret,
      fb_exchange_token: shortLivedToken,
    },
  });
  return { accessToken: data.access_token, expiresInSeconds: data.expires_in ?? null };
}

/** Step 3: list the Facebook Pages this user manages, each with its own (non-expiring) Page access token. */
export async function fetchManagedPages(userAccessToken: string): Promise<MetaPage[]> {
  const { data } = await graph.get('/me/accounts', {
    params: {
      access_token: userAccessToken,
      fields: 'id,name,category,fan_count,access_token,instagram_business_account',
    },
  });
  return data.data as MetaPage[];
}

/** Step 4: get the Instagram Professional account linked to a Page, if any. */
export async function fetchInstagramBusinessAccount(pageId: string, pageAccessToken: string) {
  const { data } = await graph.get(`/${pageId}`, {
    params: {
      fields: 'instagram_business_account{id,username,name,followers_count,profile_picture_url}',
      access_token: pageAccessToken,
    },
  });
  return data.instagram_business_account as
    | { id: string; username: string; name: string; followers_count: number; profile_picture_url: string }
    | undefined;
}

/** Step 5: subscribe the app to a Page's webhook fields (messages, postbacks, reads). */
export async function subscribePageToWebhooks(pageId: string, pageAccessToken: string): Promise<void> {
  await graph.post(`/${pageId}/subscribed_apps`, null, {
    params: {
      subscribed_fields: 'messages,messaging_postbacks,message_reads,message_reactions',
      access_token: pageAccessToken,
    },
  });
}

/** Sends a text message back to a customer via Messenger (Page) or Instagram Messaging. */
export async function sendMetaMessage(params: {
  pageId: string;
  pageAccessToken: string;
  recipientId: string; // PSID (Messenger) or IGSID (Instagram)
  text: string;
}): Promise<{ message_id: string }> {
  const { data } = await graph.post(
    `/${params.pageId}/messages`,
    {
      messaging_type: 'RESPONSE',
      recipient: { id: params.recipientId },
      message: { text: params.text },
    },
    { params: { access_token: params.pageAccessToken } },
  );
  return data;
}
