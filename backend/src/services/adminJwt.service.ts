import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';

export function signAdminToken(params: { adminId: string; email: string }): string {
  return jwt.sign(
    { sub: params.adminId, email: params.email, scope: 'admin' },
    env.adminJwtSecret,
    { expiresIn: env.adminJwtExpiresIn } as SignOptions,
  );
}
