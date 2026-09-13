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

export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : null;
  if (!token) return fail(res, 'Missing or invalid Authorization header.', 401);

  try {
    const payload = jwt.verify(token, env.jwtSecret) as JwtPayload;
    req.userId = payload.sub;
    req.tenantId = payload.tenantId;
    req.role = payload.role;

    next();
  } catch {
    return fail(res, 'Invalid or expired token.', 401);
  }
}

export function requireRole(...roles: string[]) {
  return (req: AuthedRequest, res: Response, next: NextFunction) => {
    if (!req.role || !roles.includes(req.role)) {
      return fail(res, 'You do not have permission to perform this action.', 403);
    }
    next();
  };
}
