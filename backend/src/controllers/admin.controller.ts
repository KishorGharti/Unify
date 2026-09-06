import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { Response } from 'express';
import { prisma } from '../db/prisma';
import { signAdminToken } from '../services/adminJwt.service';
import { AdminAuthedRequest } from '../middleware/adminAuth';
import { ok, fail } from '../utils/apiResponse';

function toAdminJson(admin: { id: string; email: string; fullName: string; createdAt: Date }) {
  return { id: admin.id, email: admin.email, full_name: admin.fullName, created_at: admin.createdAt.toISOString() };
}

function toAllowedEmailJson(row: { id: string; email: string; note: string | null; createdAt: Date; addedByAdmin: { fullName: string } }) {
  return {
    id: row.id,
    email: row.email,
    note: row.note,
    added_by: row.addedByAdmin.fullName,
    created_at: row.createdAt.toISOString(),
  };
}

// POST /admin/login - there is no public admin signup route by design;
// admin accounts are created with `npm run create-admin` (see scripts/createAdmin.ts).
export async function adminLogin(req: AdminAuthedRequest, res: Response) {
  const { password } = req.body ?? {};
  const email = (req.body?.email as string | undefined)?.trim().toLowerCase();
  if (!email || !password) return fail(res, 'email and password are required.', 422);

  const admin = await prisma.adminUser.findUnique({ where: { email } });
  if (!admin) return fail(res, 'Invalid email or password.', 401);

  const passwordMatches = await bcrypt.compare(password, admin.passwordHash);
  if (!passwordMatches) return fail(res, 'Invalid email or password.', 401);

  const token = signAdminToken({ adminId: admin.id, email: admin.email });
  return ok(res, { token, admin: toAdminJson(admin) });
}

// GET /admin/me
export async function adminMe(req: AdminAuthedRequest, res: Response) {
  const admin = await prisma.adminUser.findUnique({ where: { id: req.adminId } });
  if (!admin) return fail(res, 'Admin not found.', 404);
  return ok(res, toAdminJson(admin));
}

// GET /admin/allowed-emails - the invite list gating signup.
export async function listAllowedEmails(_req: AdminAuthedRequest, res: Response) {
  const rows = await prisma.allowedEmail.findMany({
    include: { addedByAdmin: true },
    orderBy: { createdAt: 'desc' },
  });
  return ok(res, rows.map(toAllowedEmailJson));
}

// POST /admin/allowed-emails { email, full_name, company_name, note? } -
// grants an email login access. Passwordless: this creates the person's
// account (Tenant + User) immediately, so they can log straight in with
// email + emailed OTP - there's no separate signup step in the app.
// full_name/company_name are only required the first time an email is
// approved; re-approving a previously revoked email just restores access to
// its existing account.
export async function addAllowedEmail(req: AdminAuthedRequest, res: Response) {
  const { note } = req.body ?? {};
  const email = (req.body?.email as string | undefined)?.trim().toLowerCase();
  const fullName = (req.body?.full_name as string | undefined)?.trim();
  const companyName = (req.body?.company_name as string | undefined)?.trim();
  if (!email) return fail(res, 'email is required.', 422);

  const existingAllowed = await prisma.allowedEmail.findUnique({ where: { email } });
  if (existingAllowed) return fail(res, 'That email is already approved.', 409);

  const existingUser = await prisma.user.findUnique({ where: { email } });
  if (!existingUser && (!fullName || !companyName)) {
    return fail(res, 'full_name and company_name are required to create a new account.', 422);
  }

  const row = await prisma.allowedEmail.create({
    data: { email, note: note ?? null, addedByAdminId: req.adminId! },
    include: { addedByAdmin: true },
  });

  if (!existingUser) {
    // Random password, hashed and stored for DB integrity - the account is
    // passwordless in practice, nobody is ever shown or types this value.
    const randomPassword = crypto.randomBytes(24).toString('hex');
    const passwordHash = await bcrypt.hash(randomPassword, 12);
    const tenant = await prisma.tenant.create({ data: { name: companyName! } });
    await prisma.user.create({
      data: { email, passwordHash, fullName: fullName!, role: 'owner', tenantId: tenant.id },
    });
  }

  return ok(res, toAllowedEmailJson(row), 201);
}

// DELETE /admin/allowed-emails/{id} - revokes access. The account itself is
// untouched (so re-approving the same email later restores it as-is), but
// both login and requestPasswordReset check this list, so a revoked email
// can no longer log in or request a password code. Any JWT already issued
// to them stays valid until it expires - add a token blocklist if you need
// to also kill an active session.
export async function removeAllowedEmail(req: AdminAuthedRequest, res: Response) {
  const { id } = req.params;
  const existing = await prisma.allowedEmail.findUnique({ where: { id } });
  if (!existing) return fail(res, 'Not found.', 404);

  await prisma.allowedEmail.delete({ where: { id } });
  return ok(res, { removed: true });
}

// GET /admin/users - read-only visibility into who has actually signed up.
export async function listUsers(_req: AdminAuthedRequest, res: Response) {
  const users = await prisma.user.findMany({
    include: { tenant: true },
    orderBy: { createdAt: 'desc' },
  });
  return ok(
    res,
    users.map((u) => ({
      id: u.id,
      email: u.email,
      full_name: u.fullName,
      role: u.role,
      tenant_name: u.tenant.name,
      created_at: u.createdAt.toISOString(),
    })),
  );
}
