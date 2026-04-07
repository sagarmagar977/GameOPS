import { Router } from 'express';
import { ok } from '../lib/http.js';

const router = Router();

router.get('/', (_req, res) => {
  ok(res, {
    status: 'ok',
    service: 'gameops-backend',
    timestamp: new Date().toISOString(),
  });
});

export default router;
