# MongoDB Atlas setup

The backend runs on your MongoDB Atlas cluster:
`mongodb+srv://thealgora99_db_user:<db_password>@cluster0.ghspnoc.mongodb.net/?appName=Cluster0`

You need three things from Atlas before this works: the real database
password, the connecting machine's IP allowed through the firewall, and a
database name in the URL.

## 1. Get the real database user password

This is **not** your Atlas account login password — it's the password for
the database user `thealgora99_db_user`, set when that user was created.

- Atlas dashboard → **Database Access** (left sidebar) → find `thealgora99_db_user`.
- If you don't remember the password: click **Edit** → **Edit Password** →
  set a new one. (You can't reveal the existing one, only rotate it.)

## 2. Allow this machine to connect (Network Access)

- Atlas dashboard → **Network Access** (left sidebar) → **Add IP Address**.
- For local development, easiest is **Allow Access from Anywhere** (`0.0.0.0/0`).
  Fine for a dev cluster; for production, restrict this to your server's
  actual IP once you deploy.

## 3. Fill in `backend/.env`

```bash
DATABASE_URL="mongodb+srv://thealgora99_db_user:<real-password-here>@cluster0.ghspnoc.mongodb.net/algora?retryWrites=true&w=majority&appName=Cluster0"
```

Notes on this URL:
- Replace `<real-password-here>` with the password from step 1. If it
  contains special characters (`@ : / ? # &`), URL-encode them (e.g. `@` → `%40`).
- `/algora` right after the host is the **database name** — Mongo doesn't
  default one, and without it Prisma errors. Any name works; `algora` is used
  throughout this project's docs.
- Keep `retryWrites=true&w=majority` — recommended defaults for Atlas.

## 4. Push the schema

MongoDB has no SQL-style migration history, so instead of `prisma migrate`,
use:

```bash
cd backend
npx prisma db push
```

This creates the `Tenant`, `User`, `Channel`, `Conversation`, `Message`,
`AllowedEmail`, and `AdminUser` collections (and their indexes, e.g. the
unique index on `User.email`) in your `algora` database. Re-run this any time
you change `prisma/schema.prisma`.

Verify any time with:
```bash
npx prisma studio
```
Opens a local web UI (usually http://localhost:5555) to browse the actual
documents in Atlas.

## 5. Run the backend

```bash
npm run dev
```

`GET http://localhost:4000/health` → `{"status":"ok"}` means it connected.

## Troubleshooting

- **`Server selection timeout` / connection hangs** → almost always Network
  Access (step 2) — the connecting IP isn't allowed yet.
- **`Authentication failed`** → wrong password (step 1), or a special
  character in the password isn't URL-encoded.
- **`the URL must contain a database name`** → missing `/algora` in the URL (step 3).
