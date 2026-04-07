import { Router } from 'express';
import { query } from '../lib/db.js';
import { fail, ok } from '../lib/http.js';
import { cashoutSchema } from '../validators/gameValidators.js';

const router = Router();

router.get('/', async (_req, res) => {
  try {
    const result = await query(
      `select c.*,
              json_build_object('id', g.id, 'name', g.name, 'slug', g.slug) as games,
              case
                when gc.id is null then null
                else json_build_object('id', gc.id, 'username', gc.username, 'label', gc.label)
              end as game_credentials
       from public.cashouts c
       join public.games g on g.id = c.game_id
       left join public.game_credentials gc on gc.id = c.credential_id
       order by c.created_at desc
       limit 50`,
    );
    ok(res, result.rows);
  } catch (error) {
    fail(res, 'Failed to fetch cashouts', 500, error.message);
  }
});

router.post('/', async (req, res) => {
  const parsed = cashoutSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid cashout payload', 400, parsed.error.flatten());
  }

  try {
    const result = await query(
      `insert into public.cashouts (game_id, credential_id, player_name, amount, status, notes)
       values ($1, $2, $3, $4, $5, $6)
       returning *`,
      [
        parsed.data.game_id,
        parsed.data.credential_id,
        parsed.data.player_name,
        parsed.data.amount,
        parsed.data.status,
        parsed.data.notes,
      ],
    );
    ok(res, result.rows[0], 201);
  } catch (error) {
    fail(res, 'Failed to create cashout', 500, error.message);
  }
});

export default router;
