import { Router } from 'express';
import * as webhooksController from '../controllers/webhooks.controller';

const router = Router();

router.get('/meta', webhooksController.verifyWebhook);
router.post('/meta', webhooksController.receiveWebhook);

export default router;
