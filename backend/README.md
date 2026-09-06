# Algora Backend

Node.js + TypeScript + Express + Prisma (MongoDB) + Socket.IO backend for
the Algora Flutter app. Implements real Meta (Facebook Messenger + Instagram
Messaging) OAuth, webhook receiving, and message sending — the pieces that
can't safely live in the mobile app — plus a separate, invite-only access
control system with its own admin panel (see section 7).

Routes are mounted to match `ApiEndpoints` in
[`lib/core/constants/api_endpoints.dart`](../lib/core/constants/api_endpoints.dart),
and JSON field names (snake_case) match what the Dart models' `fromJson` expect.

## 0. MongoDB setup (Atlas)

This backend needs your MongoDB Atlas cluster reachable and its real password
filled in — see [MONGODB_SETUP.md](MONGODB_SETUP.md) for the full
step-by-step. Short version: get the database user's password from Atlas →
Database Access, allow your IP through Atlas → Network Access, then set
`DATABASE_URL` in `.env`.

## 1. Local setup

```bash
cd backend
npm install
cp .env.example .env      # then fill in DATABASE_URL (see step 0) and the values below
npx prisma db push         # creates the collections/indexes in your MongoDB database
npm run dev                # starts on http://localhost:4000
```

`GET http://localhost:4000/health` should return `{"status":"ok"}`.

You still need to fill in `DATABASE_URL` (step 0) and the four `META_*`
values below before this will boot and before Meta login/webhooks work.
`JWT_SECRET`, `ADMIN_JWT_SECRET`, `TOKEN_ENCRYPTION_KEY`, and
`META_WEBHOOK_VERIFY_TOKEN` were already generated into `backend/.env` during
initial setup.

## 2. Meta app setup (Facebook + Instagram)

1. Create a Business Portfolio at business.facebook.com if you don't have one.
2. Create an app at developers.facebook.com/apps → type **Business**.
3. Add products **Messenger** and **Instagram**.
4. App Dashboard → Settings → Basic: copy **App ID** and **App Secret** into
   `.env` as `META_APP_ID` / `META_APP_SECRET`.
5. App Dashboard → Facebook Login → Settings → **Valid OAuth Redirect URIs**:
   add the exact value you put in `META_OAUTH_REDIRECT_URI`
   (e.g. `https://<your-ngrok-domain>/api/v1/channels/meta/oauth/callback`).
   This must be publicly reachable — Meta will not redirect to `localhost`.
6. Local dev tunnel: `ngrok http 4000`, then use the printed `https://*.ngrok-free.app`
   host in both `META_OAUTH_REDIRECT_URI` and the webhook URL below.
7. App Dashboard → Webhooks → Add Callback URL:
   - Callback URL: `https://<your-ngrok-domain>/webhooks/meta`
   - Verify Token: same value as `META_WEBHOOK_VERIFY_TOKEN` in `.env`
   - Subscribe to: `messages`, `messaging_postbacks`, `message_reads` for both
     the **Page** and **Instagram** objects.
8. Roles → Add yourself (and any test users) as an **Admin** or **Tester** —
   required before App Review to use live messaging on real Pages/IG accounts.
9. Before production: submit for **App Review** requesting Advanced Access
   for `pages_messaging`, `pages_manage_metadata`, `pages_read_engagement`,
   `instagram_basic`, `instagram_manage_messages`, `business_management`
   (screen-recorded demo of the exact flow below is required).

## 3. The connection flow this backend implements

1. Flutter calls `GET /api/v1/channels/meta/oauth/start` (Owner/Admin only) →
   gets back a Facebook Login dialog URL, opens it in an in-app browser/webview.
2. User approves → Meta redirects to `GET /api/v1/channels/meta/oauth/callback`
   on **this server** (not the app) with a `code`.
3. Backend exchanges `code` → short-lived user token → long-lived user token →
   calls `/me/accounts` to list the user's Pages (each with its own
   non-expiring Page access token) and their linked Instagram Business accounts.
   Held server-side only, in memory, for 10 minutes.
4. Flutter calls `GET /api/v1/channels/meta/facebook/pages` (or
   `.../instagram/accounts`) to show the picker UI.
5. User picks one → Flutter calls `POST /api/v1/channels/meta/facebook/connect`
   `{ "page_id": "..." }` (or `/instagram/connect` with `{ ig_user_id, page_id }`).
   The backend looks up the real Page token from step 3 itself — **the client
   never sees or sends an access token**.
6. Backend subscribes the Page to webhooks (`/{page-id}/subscribed_apps`),
   encrypts the Page token (AES-256-GCM) and stores it in the `Channel` table.
7. Incoming customer messages arrive at `POST /webhooks/meta`, verified via
   the `X-Hub-Signature-256` header, stored as `Conversation`/`Message` rows,
   and pushed live over Socket.IO to `tenant:{tenantId}`.
8. Agent replies via `POST /api/v1/inbox/conversations/{id}/messages` call the
   Send API (`/{page-id}/messages`) using the stored, decrypted Page token.

## 4. Pointing the Flutter app at this backend

In [`lib/core/constants/api_endpoints.dart`](../lib/core/constants/api_endpoints.dart):

```dart
static const String baseUrl = 'http://localhost:4000/api/v1'; // or your deployed URL
static const String wsUrl = 'ws://localhost:4000';            // Socket.IO, see below
```

(Use your machine's LAN IP instead of `localhost` when running on a physical
device/emulator that isn't `localhost`-mapped, e.g. `10.0.2.2` for the Android
emulator.)

Then swap the **mock repositories** for real HTTP calls through
[`api_client.dart`](../lib/core/network/api_client.dart) — the interfaces
already match this API 1:1, so only the method bodies change:

- [`channel_repository.dart`](../lib/features/channels/data/channel_repository.dart) → `GET/POST /channels/...`
- [`inbox_repository.dart`](../lib/features/inbox/data/inbox_repository.dart) → `GET /inbox/conversations...`
- [`chat_repository.dart`](../lib/features/chat/data/chat_repository.dart) → `POST /inbox/conversations/{id}/messages`
- [`auth_repository.dart`](../lib/features/auth/data/auth_repository.dart) → `POST /auth/login`, `/signup`, `GET /auth/me`

**Not done yet, and worth flagging**: [`socket_service.dart`](../lib/core/websocket/socket_service.dart)'s
`AlgoraWebSocketService` is currently a no-op stub — `connect()` just flips a
boolean and `emit()` does nothing, so it's not actually wired to this
server's Socket.IO endpoint. To get live message push working you'll need to
add the `socket_io_client` Flutter package and implement `connect()` to open
a real connection with `auth: { token: <JWT> }`, listening for the
`algora_event` event this backend emits (payload shape matches
`SocketEvent.fromJson` in [`socket_events.dart`](../lib/core/websocket/socket_events.dart)).
Say the word and I'll wire that up too.

## 5. What this backend does NOT cover yet

Scoped to what real Meta messaging requires: auth, channel connect/disconnect,
webhook receive, and inbox send/receive. Not implemented (still mocked on the
Flutter side, no server routes): **team management, billing/subscription,
dashboard analytics**. These don't block real Facebook/Instagram messaging —
add routes/tables for them the same way when you're ready.

## 6. Invite-only accounts, password login & the admin panel

There is no signup screen in the app. Accounts are created entirely from the
separate admin panel, which generates a random password nobody is ever shown.
Login itself is password-only (`POST /api/v1/auth/login`) — OTP exists for
exactly one purpose: setting/resetting that password
(`POST /api/v1/auth/password/forgot` then `POST /api/v1/auth/password/reset`
— see `auth.controller.ts`). A first-time user goes through the same "Forgot
password?" flow to set their first real password, since they were never given
one; after that, they just log in with it normally.

Email is sent via Gmail SMTP (see `EMAIL_USER`/`EMAIL_APP_PASSWORD` in `.env`
— an "app password" from the sending Google account's Security settings, not
its real login password). In non-production (`NODE_ENV !== 'production'`),
the code is also logged to the server console
(`[OTP] password code for ...: 123456`) so you can test without checking a
real inbox every time.

**First-time setup — create your own admin account** (there's no signup form
for this on purpose):
```bash
cd backend
npm run create-admin -- --email you@example.com --password 'Str0ngPass!' --name "Your Name"
```

**Using the panel:**
1. Start the backend (`npm run dev`).
2. Open `http://localhost:4000/admin` in a browser.
3. Log in with the email/password from the command above.
4. Under **Approve a new email**, enter the person's email, full name, and
   company/workspace name, then **Approve**. This immediately creates their
   Tenant + User account (role: owner) with a random password. They open the
   Flutter app, go to Login → "Forgot password?", enter that email, and set
   their own password via the emailed code — then log in normally from then
   on. Full name/company are only required the first time an email is
   approved; re-approving a previously revoked email (see below) just
   restores access to the account that already exists.
5. **Revoke** removes the email from the allow-list, which blocks future
   `login` and `password/forgot` calls for it — the account itself isn't
   deleted, and any JWT already issued to them stays valid until it expires.
6. **Registered users** below it is read-only visibility into everyone with
   an account.

This is a completely separate system from the in-app **Team Members** screen
(Settings → Team Members) — that manages Owner/Admin/Agent roles *within* a
workspace that already exists; this admin panel controls who can log in at
all.

The panel is served as static files from `backend/public/admin/`, calling
`/api/admin/*` routes protected by their own JWT (`ADMIN_JWT_SECRET` — a
different secret than the tenant `JWT_SECRET`, so one token type can never be
used where the other is expected).

## 7. Production notes

- Swap the in-memory `pendingConnections.store.ts` for Redis (or a short-lived
  DB table) if you run more than one backend instance.
- Already on MongoDB Atlas (see step 0) — the free (M0) tier is fine to
  start; upgrade as load grows.
- Put this behind HTTPS (required by Meta for both the OAuth redirect and the
  webhook URL) — e.g. deploy behind a reverse proxy/load balancer that
  terminates TLS. This also protects the `/admin` panel's login.
- Rotate `JWT_SECRET` / `ADMIN_JWT_SECRET` / `TOKEN_ENCRYPTION_KEY` per
  environment; never commit `.env`.
- Once deployed, restrict MongoDB Atlas Network Access from "Anywhere" down
  to your server's actual IP.
