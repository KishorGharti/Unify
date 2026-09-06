import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { asyncHandler } from '../utils/asyncHandler';
import { requireAuth } from '../middleware/auth';

const router = Router();

// Paths are mounted under /api/v1, matching ApiEndpoints in api_endpoints.dart.
// Accounts are created by an admin (see admin.routes.ts) - there is no
// signup route. Login is password-only; OTP exists solely to set/reset that
// password (POST /password/forgot then /password/reset) - used both for a
// brand new account's first-ever password (an admin's approval only ever
// generates a random one nobody knows) and for a genuinely forgotten one.
router.post('/login', asyncHandler(authController.login));
router.post('/password/forgot', asyncHandler(authController.requestPasswordReset));
router.post('/password/reset', asyncHandler(authController.resetPassword));
router.post('/logout', requireAuth, asyncHandler(authController.logout));
router.get('/me', requireAuth, asyncHandler(authController.me));

export default router;
