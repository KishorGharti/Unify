import { MetaPage } from './meta.service';
import { InstagramProfile } from './instagramLogin.service';

interface PendingConnection {
  pages: MetaPage[];
  fetchedAt: number;
}

const store = new Map<string, PendingConnection>();
const TTL_MS = 10 * 60 * 1000;

export function setPendingPages(tenantId: string, pages: MetaPage[]): void {
  store.set(tenantId, { pages, fetchedAt: Date.now() });
}

export function getPendingPages(tenantId: string): MetaPage[] | null {
  const entry = store.get(tenantId);
  if (!entry) return null;
  if (Date.now() - entry.fetchedAt > TTL_MS) {
    store.delete(tenantId);
    return null;
  }
  return entry.pages;
}

export function clearPendingPages(tenantId: string): void {
  store.delete(tenantId);
}

interface PendingInstagramLogin {
  account: InstagramProfile & { accessToken: string };
  fetchedAt: number;
}

const instagramLoginStore = new Map<string, PendingInstagramLogin>();

export function setPendingInstagramLogin(tenantId: string, account: InstagramProfile & { accessToken: string }): void {
  instagramLoginStore.set(tenantId, { account, fetchedAt: Date.now() });
}

export function getPendingInstagramLogin(tenantId: string): (InstagramProfile & { accessToken: string }) | null {
  const entry = instagramLoginStore.get(tenantId);
  if (!entry) return null;
  if (Date.now() - entry.fetchedAt > TTL_MS) {
    instagramLoginStore.delete(tenantId);
    return null;
  }
  return entry.account;
}

export function clearPendingInstagramLogin(tenantId: string): void {
  instagramLoginStore.delete(tenantId);
}
