import { Router } from 'express';
import { query } from '../lib/db.js';
import { fail, ok } from '../lib/http.js';
import { cashoutRuleSchema } from '../validators/gameValidators.js';

const router = Router();

router.get('/', async (_req, res) => {
  try {
    const result = await query(
      `select cr.*, json_build_object('id', g.id, 'name', g.name, 'slug', g.slug) as games
       from public.cashout_rules cr
       join public.games g on g.id = cr.game_id
       order by cr.created_at desc`,
    );
    ok(res, result.rows);
  } catch (error) {
    fail(res, 'Failed to fetch cashout rules', 500, error.message);
  }
});

router.post('/', async (req, res) => {
  const parsed = cashoutRuleSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid cashout rule payload', 400, parsed.error.flatten());
  }

  try {
    const result = await query(
      `insert into public.cashout_rules (game_id, freeplay_label, payout_min, payout_max, slope_percent, is_freeplay_enabled, notes)
       values ($1, $2, $3, $4, $5, $6, $7)
       on conflict (game_id) do update set
         freeplay_label = excluded.freeplay_label,
         payout_min = excluded.payout_min,
         payout_max = excluded.payout_max,
         slope_percent = excluded.slope_percent,
         is_freeplay_enabled = excluded.is_freeplay_enabled,
         notes = excluded.notes
       returning *`,
      [
        parsed.data.game_id,
        parsed.data.freeplay_label,
        parsed.data.payout_min,
        parsed.data.payout_max,
        parsed.data.slope_percent,
        parsed.data.is_freeplay_enabled,
        parsed.data.notes,
      ],
    );
    ok(res, result.rows[0], 201);
  } catch (error) {
    fail(res, 'Failed to save cashout rule', 500, error.message);
  }
});

router.put('/:id', async (req, res) => {
  const parsed = cashoutRuleSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid cashout rule payload', 400, parsed.error.flatten());
  }

  try {
    const fields = Object.entries(parsed.data);
    if (fields.length === 0) {
      return fail(res, 'No fields provided to update', 400);
    }

    const setClause = fields.map(([key], index) => `${key} = $${index + 1}`).join(', ');
    const values = fields.map(([, value]) => value);
    const result = await query(
      `update public.cashout_rules set ${setClause} where id = $${fields.length + 1} returning *`,
      [...values, req.params.id],
    );
    ok(res, result.rows[0]);
  } catch (error) {
    fail(res, 'Failed to update cashout rule', 500, error.message);
  }
});

export default router;
