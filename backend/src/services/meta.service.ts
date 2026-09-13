import axios from 'axios';
import { env } from '../config/env';

const graph = axios.create({
  baseURL: `https://graph.facebook.com/${env.meta.graphApiVersion}`,
  timeout: 15000,
});

export interface MetaPage {
  id: string;
  name: string;
  category?: string;
  fan_count?: number;
  access_token: string;
  instagram_business_account?: { id: string };
}

export interface MetaTokenExchangeResult {
  accessToken: string;
  expiresInSeconds: number | null;
}

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

export async function fetchManagedPages(userAccessToken: string): Promise<MetaPage[]> {
  const { data } = await graph.get('/me/accounts', {
    params: {
      access_token: userAccessToken,
      fields: 'id,name,category,fan_count,access_token,instagram_business_account',
    },
  });
  return data.data as MetaPage[];
}

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

export async function subscribePageToWebhooks(pageId: string, pageAccessToken: string): Promise<void> {
  await graph.post(`/${pageId}/subscribed_apps`, null, {
    params: {
      subscribed_fields: 'messages,messaging_postbacks,message_reads,message_reactions',
      access_token: pageAccessToken,
    },
  });
}

export async function sendMetaMessage(params: {
  pageId: string;
  pageAccessToken: string;
  recipientId: string;
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
