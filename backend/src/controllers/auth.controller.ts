import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { Request, Response } from 'express';
import { prisma } from '../db/prisma';
import { signAuthToken } from '../services/jwt.service';
import { sendPasswordResetEmail } from '../services/email.service';
import { ok, fail } from '../utils/apiResponse';
import { AuthedRequest } from '../middleware/auth';
import { env } from '../config/env';

const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes
const OTP_TTL_MINUTES = OTP_TTL_MS / 60000;
const OTP_MAX_ATTEMPTS = 5;

type TenantUser = { id: string; email: string; fullName: string; role: string; tenantId: string; createdAt: Date; hasPassword: boolean };

function toUserJson(user: TenantUser, tenant?: { id: string; name: string } | null) {
  return {
    id: user.id,
    email: user.email,
    full_name: user.fullName,
    avatar_url: null,
    role: user.role,
    tenant_id: user.tenantId,
    has_password: user.hasPassword,
    current_tenant: tenant ? { id: tenant.id, name: tenant.name } : null,
    available_tenants: tenant ? [{ id: tenant.id, name: tenant.name }] : [],
    created_at: user.createdAt.toISOString(),
  };
}

function generateOtpCode(): string {
  return crypto.randomInt(100000, 1000000).toString(); // 6 digits
}

// Only emails already on the AllowedEmail list (i.e. not revoked) get a code.
async function assertEmailIsApproved(email: string): Promise<{ ok: true } | { ok: false; message: string; status: number }> {
  const allowed = await prisma.allowedEmail.findUnique({ where: { email } });
  if (!allowed) {
    return { ok: false, message: 'This email has not been given access. Ask your administrator to add it.', status: 403 };
  }
  return { ok: true };
}

// Login is password-only. OTP exists for exactly one purpose: proving you
// own an admin-approved email so you can set/reset your password - both for
// a brand new account (whose password is a random value nobody knows) and
// for a genuinely forgotten one. There's no separate "log in with a code"
// path.
async function issuePasswordResetOtp(userId: string, email: string): Promise<void> {
  const code = generateOtpCode();
  const otpCodeHash = await bcrypt.hash(code, 10);
  await prisma.user.update({
    where: { id: userId },
    data: { otpCodeHash, otpExpiresAt: new Date(Date.now() + OTP_TTL_MS), otpAttempts: 0 },
  });
  await sendPasswordResetEmail(email, code, OTP_TTL_MINUTES);

  // Dev convenience only - lets you test the flow without checking a real
  // inbox every time. Never logs in production.
  if (env.nodeEnv !== 'production') {
    console.log(`[OTP] password code for ${email}: ${code} (expires in ${OTP_TTL_MINUTES} min)`);
  }
}

// Verifies `code` against the stored, hashed, time-limited OTP for `userId`
// and clears it on success.
async function consumeOtp(userId: string, code: string): Promise<{ ok: true } | { ok: false; message: string; status: number }> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user || !user.otpCodeHash || !user.otpExpiresAt) {
    return { ok: false, message: 'Invalid or expired code. Request a new one.', status: 401 };
  }
  if (user.otpExpiresAt < new Date()) {
    return { ok: false, message: 'This code has expired. Request a new one.', status: 401 };
  }
  if (user.otpAttempts >= OTP_MAX_ATTEMPTS) {
    return { ok: false, message: 'Too many incorrect attempts. Request a new code.', status: 429 };
  }

  const matches = await bcrypt.compare(String(code), user.otpCodeHash);
  if (!matches) {
    await prisma.user.update({ where: { id: user.id }, data: { otpAttempts: { increment: 1 } } });
    return { ok: false, message: 'Incorrect code.', status: 401 };
  }

  await prisma.user.update({ where: { id: user.id }, data: { otpCodeHash: null, otpExpiresAt: null, otpAttempts: 0 } });
  return { ok: true };
}

// POST /auth/login { email, password }
// Deliberately gives the exact same "Invalid email or password." message
// (and 401) whether the email was never approved, was revoked, doesn't have
// an account, or the password is just wrong - never reveals which case it
// was, so this can't be used to enumerate approved/registered emails.
export async function login(req: Request, res: Response) {
  const { password } = req.body ?? {};
  const email = (req.body?.email as string | undefined)?.trim().toLowerCase();
  if (!email || !password) return fail(res, 'email and password are required.', 422);
  const invalid = () => fail(res, 'Invalid email or password.', 401);

  const approved = await assertEmailIsApproved(email);
  if (!approved.ok) return invalid();

  const user = await prisma.user.findUnique({ where: { email }, include: { tenant: true } });
  if (!user) return invalid();

  const passwordMatches = await bcrypt.compare(password, user.passwordHash);
  if (!passwordMatches) return invalid();

  const token = signAuthToken({ userId: user.id, tenantId: user.tenantId, role: user.role });
  return ok(res, { token, user: toUserJson(user, user.tenant) });
}

// POST /auth/password/forgot { email }
// Step 1 of setting/resetting a password - covers both a brand new account's
// first-ever password and a genuinely forgotten one; the app doesn't
// distinguish the two.
export async function requestPasswordReset(req: Request, res: Response) {
  const email = (req.body?.email as string | undefined)?.trim().toLowerCase();
  if (!email) return fail(res, 'email is required.', 422);

  const approved = await assertEmailIsApproved(email);
  if (!approved.ok) return fail(res, approved.message, approved.status);

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    return fail(res, 'No account found for this email. Ask your administrator to add it again.', 403);
  }

  await issuePasswordResetOtp(user.id, email);
  return ok(res, { message: 'Code sent.', expires_in_seconds: OTP_TTL_MS / 1000 });
}

// POST /auth/password/reset { email, code, new_password }
// Step 2 - sets the password and logs the user in.
export async function resetPassword(req: Request, res: Response) {
  const { code } = req.body ?? {};
  const newPassword = req.body?.new_password as string | undefined;
  const email = (req.body?.email as string | undefined)?.trim().toLowerCase();
  if (!email || !code || !newPassword) return fail(res, 'email, code and new_password are required.', 422);
  if (newPassword.length < 8) return fail(res, 'Password must be at least 8 characters.', 422);

  const user = await prisma.user.findUnique({ where: { email }, include: { tenant: true } });
  if (!user) return fail(res, 'Invalid or expired code. Request a new one.', 401);

  const result = await consumeOtp(user.id, code);
  if (!result.ok) return fail(res, result.message, result.status);

  const passwordHash = await bcrypt.hash(newPassword, 12);
  await prisma.user.update({ where: { id: user.id }, data: { passwordHash, hasPassword: true } });

  const token = signAuthToken({ userId: user.id, tenantId: user.tenantId, role: user.role });
  return ok(res, { token, user: toUserJson({ ...user, hasPassword: true }, user.tenant) });
}

// GET /auth/me
export async function me(req: AuthedRequest, res: Response) {
  const user = await prisma.user.findUnique({ where: { id: req.userId }, include: { tenant: true } });
  if (!user) return fail(res, 'User not found.', 404);
  return ok(res, toUserJson(user, user.tenant));
}

// POST /auth/logout - stateless JWT, nothing to invalidate server-side without a
// token blocklist; kept as a no-op endpoint so the Flutter client's call succeeds.
export async function logout(_req: Request, res: Response) {
  return ok(res, { loggedOut: true });
}
