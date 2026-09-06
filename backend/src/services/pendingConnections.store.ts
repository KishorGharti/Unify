import { MetaPage } from './meta.service';

// Holds the Pages (with their access tokens + linked IG accounts) fetched right
// after a tenant completes the Meta OAuth dialog, so the two-step
// "pick a Page to connect" UI flow in connect_facebook_screen.dart /
// connect_instagram_screen.dart has something to read from.
//
// This is process-memory only, which is fine for a single backend instance in
// development. For a multi-instance production deployment, replace this with
// a Redis hash (or a short-lived DB table) keyed by tenantId with a TTL.

interface PendingConnection {
  pages: MetaPage[];
  fetchedAt: number;
}

const store = new Map<string, PendingConnection>();
const TTL_MS = 10 * 60 * 1000; // 10 minutes

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
