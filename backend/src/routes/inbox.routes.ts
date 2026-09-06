import { Router } from 'express';
import * as inboxController from '../controllers/inbox.controller';
import { asyncHandler } from '../utils/asyncHandler';
import { requireAuth } from '../middleware/auth';

const router = Router();
router.use(requireAuth);

router.get('/conversations', asyncHandler(inboxController.getConversations));
router.get('/conversations/:id', asyncHandler(inboxController.getConversationById));
router.get('/conversations/:id/messages', asyncHandler(inboxController.getMessages));
router.post('/conversations/:id/messages', asyncHandler(inboxController.sendMessage));
router.post('/conversations/:id/notes', asyncHandler(inboxController.addInternalNote));
router.post('/conversations/:id/assign', asyncHandler(inboxController.assignConversation));
router.post('/conversations/:id/status', asyncHandler(inboxController.updateStatus));
router.post('/conversations/:id/tags', asyncHandler(inboxController.updateTags));

export default router;
