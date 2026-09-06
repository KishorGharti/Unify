import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';

export function signAuthToken(params: { userId: string; tenantId: string; role: string }): string {
  return jwt.sign(
    { sub: params.userId, tenantId: params.tenantId, role: params.role },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn } as SignOptions,
  );
}
