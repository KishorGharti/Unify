import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { fail } from '../utils/apiResponse';

export interface AuthedRequest extends Request {
  userId?: string;
  tenantId?: string;
  role?: string;
}

interface JwtPayload {
  sub: string;
  tenantId: string;
  role: string;
}

/** Reads the `Authorization: Bearer <token>` header set by AuthInterceptor in the Flutter app. */
export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : null;
  if (!token) return fail(res, 'Missing or invalid Authorization header.', 401);

  try {
    const payload = jwt.verify(token, env.jwtSecret) as JwtPayload;
    req.userId = payload.sub;
    req.tenantId = payload.tenantId;
    req.role = payload.role;
    // Flutter also sends X-Tenant-ID for multi-tenant switching; trust the JWT's
    // tenant claim as the source of truth, but keep the header available if the
    // caller has switched to a tenant they belong to (extend this check once
    // multi-tenant membership is modeled).
    next();
  } catch {
    return fail(res, 'Invalid or expired token.', 401);
  }
}

/** Restricts a route to one or more roles (owner/admin/agent). */
export function requireRole(...roles: string[]) {
  return (req: AuthedRequest, res: Response, next: NextFunction) => {
    if (!req.role || !roles.includes(req.role)) {
      return fail(res, 'You do not have permission to perform this action.', 403);
    }
    next();
  };
}
