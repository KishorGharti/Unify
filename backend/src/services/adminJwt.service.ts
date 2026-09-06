import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';

// Signed with adminJwtSecret (distinct from the tenant jwtSecret) and carries
// no tenantId - an admin token simply cannot pass requireAuth's tenant checks,
// and a tenant token cannot pass requireAdminAuth's signature check.
export function signAdminToken(params: { adminId: string; email: string }): string {
  return jwt.sign(
    { sub: params.adminId, email: params.email, scope: 'admin' },
    env.adminJwtSecret,
    { expiresIn: env.adminJwtExpiresIn } as SignOptions,
  );
}
