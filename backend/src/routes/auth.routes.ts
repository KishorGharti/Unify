import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { asyncHandler } from '../utils/asyncHandler';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.post('/login', asyncHandler(authController.login));
router.post('/password/forgot', asyncHandler(authController.requestPasswordReset));
router.post('/password/reset', asyncHandler(authController.resetPassword));
router.post('/logout', requireAuth, asyncHandler(authController.logout));
router.get('/me', requireAuth, asyncHandler(authController.me));

export default router;
