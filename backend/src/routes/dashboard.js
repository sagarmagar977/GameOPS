import { Router } from 'express';
import { query } from '../lib/db.js';
import { fail, ok } from '../lib/http.js';

const router = Router();

router.get('/', async (_req, res) => {
  try {
    const [gamesResult, rulesResult, cashoutsResult] = await Promise.all([
      query('select * from public.games order by name'),
      query(
        `select cr.*, json_build_object('id', g.id, 'name', g.name, 'slug', g.slug) as games
         from public.cashout_rules cr
         join public.games g on g.id = cr.game_id
         order by cr.created_at desc`,
      ),
      query(
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
      ),
    ]);

    ok(res, {
      games: gamesResult.rows,
      rules: rulesResult.rows,
      cashouts: cashoutsResult.rows,
    });
  } catch (error) {
    fail(res, 'Failed to fetch dashboard', 500, error.message);
  }
});

export default router;
