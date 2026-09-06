import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { fail } from '../utils/apiResponse';

export interface AdminAuthedRequest extends Request {
  adminId?: string;
  adminEmail?: string;
}

interface AdminJwtPayload {
  sub: string;
  email: string;
  scope: string;
}

/** Reads `Authorization: Bearer <adminToken>` - verified against ADMIN_JWT_SECRET,
 *  entirely separate from the tenant requireAuth in middleware/auth.ts. */
export function requireAdminAuth(req: AdminAuthedRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : null;
  if (!token) return fail(res, 'Missing or invalid Authorization header.', 401);

  try {
    const payload = jwt.verify(token, env.adminJwtSecret) as AdminJwtPayload;
    if (payload.scope !== 'admin') return fail(res, 'Invalid admin token.', 401);
    req.adminId = payload.sub;
    req.adminEmail = payload.email;
    next();
  } catch {
    return fail(res, 'Invalid or expired admin token.', 401);
  }
}
