import { Router } from 'express';
import * as channelsController from '../controllers/channels.controller';
import { asyncHandler } from '../utils/asyncHandler';
import { requireAuth, requireRole } from '../middleware/auth';

const router = Router();

router.get('/', requireAuth, asyncHandler(channelsController.getConnectedAccounts));

// Meta OAuth (Owner/Admin only - connecting a channel affects the whole workspace)
router.get('/meta/oauth/start', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.startOAuth));
// No requireAuth: Meta itself calls this redirect URI, not the Flutter app.
router.get('/meta/oauth/callback', asyncHandler(channelsController.oauthCallback));

router.get('/meta/facebook/pages', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.listFacebookPages));
router.post('/meta/facebook/connect', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.connectFacebookPage));

router.get('/meta/instagram/accounts', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.listInstagramAccounts));
router.post('/meta/instagram/connect', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.connectInstagramAccount));

router.post('/:id/disconnect', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.disconnectChannel));
router.get('/:id/health', requireAuth, asyncHandler(channelsController.channelHealth));

export default router;
