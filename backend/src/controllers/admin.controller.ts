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

export async function adminMe(req: AdminAuthedRequest, res: Response) {
  const admin = await prisma.adminUser.findUnique({ where: { id: req.adminId } });
  if (!admin) return fail(res, 'Admin not found.', 404);
  return ok(res, toAdminJson(admin));
}

export async function listAllowedEmails(_req: AdminAuthedRequest, res: Response) {
  const rows = await prisma.allowedEmail.findMany({
    include: { addedByAdmin: true },
    orderBy: { createdAt: 'desc' },
  });
  return ok(res, rows.map(toAllowedEmailJson));
}

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

    const randomPassword = crypto.randomBytes(24).toString('hex');
    const passwordHash = await bcrypt.hash(randomPassword, 12);
    const tenant = await prisma.tenant.create({ data: { name: companyName! } });
    await prisma.user.create({
      data: { email, passwordHash, fullName: fullName!, role: 'owner', tenantId: tenant.id },
    });
  }

  return ok(res, toAllowedEmailJson(row), 201);
}

export async function removeAllowedEmail(req: AdminAuthedRequest, res: Response) {
  const { id } = req.params;
  const existing = await prisma.allowedEmail.findUnique({ where: { id } });
  if (!existing) return fail(res, 'Not found.', 404);

  await prisma.allowedEmail.delete({ where: { id } });
  return ok(res, { removed: true });
}

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
