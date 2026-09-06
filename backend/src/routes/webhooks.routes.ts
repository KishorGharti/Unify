import { Router } from 'express';
import * as webhooksController from '../controllers/webhooks.controller';

const router = Router();

// No requireAuth: these are called by Meta's servers, authenticated instead
// via hub.verify_token (GET) and the X-Hub-Signature-256 HMAC (POST).
router.get('/meta', webhooksController.verifyWebhook);
router.post('/meta', webhooksController.receiveWebhook);

export default router;
