import { Router } from 'express';
import { query } from '../lib/db.js';
import { fail, ok } from '../lib/http.js';
import { taskSchema } from '../validators/gameValidators.js';

const router = Router();

router.post('/', async (req, res) => {
  const parsed = taskSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid task payload', 400, parsed.error.flatten());
  }

  const simulatedResult = {
    action: parsed.data.action,
    username: parsed.data.username,
    status: 'queued',
    message: 'Playwright automation is not wired yet; returning starter response.',
  };

  try {
    const result = await query(
      `insert into public.automation_tasks (game_id, credential_id, action, username, status, result)
       values ($1, $2, $3, $4, $5, $6::jsonb)
       returning *`,
      [
        parsed.data.game_id,
        parsed.data.credential_id,
        parsed.data.action,
        parsed.data.username,
        'queued',
        JSON.stringify(simulatedResult),
      ],
    );
    ok(res, result.rows[0], 201);
  } catch (error) {
    fail(res, 'Failed to create automation task', 500, error.message);
  }
});

export default router;
