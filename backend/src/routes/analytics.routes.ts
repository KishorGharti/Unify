import { Router } from 'express';
import * as analyticsController from '../controllers/analytics.controller';
import { asyncHandler } from '../utils/asyncHandler';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.get('/dashboard', requireAuth, asyncHandler(analyticsController.getDashboardMetrics));

export default router;
