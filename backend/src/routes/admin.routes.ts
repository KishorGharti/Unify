import { Router } from 'express';
import * as adminController from '../controllers/admin.controller';
import { asyncHandler } from '../utils/asyncHandler';
import { requireAdminAuth } from '../middleware/adminAuth';

const router = Router();

router.post('/login', asyncHandler(adminController.adminLogin));
router.get('/me', requireAdminAuth, asyncHandler(adminController.adminMe));

router.get('/allowed-emails', requireAdminAuth, asyncHandler(adminController.listAllowedEmails));
router.post('/allowed-emails', requireAdminAuth, asyncHandler(adminController.addAllowedEmail));
router.delete('/allowed-emails/:id', requireAdminAuth, asyncHandler(adminController.removeAllowedEmail));

router.get('/users', requireAdminAuth, asyncHandler(adminController.listUsers));

export default router;
