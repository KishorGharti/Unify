import { Router } from 'express';
import * as channelsController from '../controllers/channels.controller';
import { asyncHandler } from '../utils/asyncHandler';
import { requireAuth, requireRole } from '../middleware/auth';

const router = Router();

router.get('/', requireAuth, asyncHandler(channelsController.getConnectedAccounts));

router.get('/meta/oauth/start', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.startOAuth));

router.get('/meta/oauth/callback', asyncHandler(channelsController.oauthCallback));

router.get('/meta/facebook/pages', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.listFacebookPages));
router.post('/meta/facebook/connect', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.connectFacebookPage));

router.get('/meta/instagram/accounts', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.listInstagramAccounts));
router.post('/meta/instagram/connect', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.connectInstagramAccount));

router.get(
  '/meta/instagram-login/oauth/start',
  requireAuth,
  requireRole('owner', 'admin'),
  asyncHandler(channelsController.startInstagramLoginOAuth),
);

router.get('/meta/instagram-login/oauth/callback', asyncHandler(channelsController.instagramLoginOAuthCallback));
router.get(
  '/meta/instagram-login/accounts',
  requireAuth,
  requireRole('owner', 'admin'),
  asyncHandler(channelsController.listInstagramLoginAccounts),
);
router.post(
  '/meta/instagram-login/connect',
  requireAuth,
  requireRole('owner', 'admin'),
  asyncHandler(channelsController.connectInstagramLoginAccount),
);

router.post('/:id/disconnect', requireAuth, requireRole('owner', 'admin'), asyncHandler(channelsController.disconnectChannel));
router.get('/:id/health', requireAuth, asyncHandler(channelsController.channelHealth));

export default router;
