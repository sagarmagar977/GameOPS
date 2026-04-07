import { Router } from 'express';
import { query } from '../lib/db.js';
import { fail, ok, unwrap } from '../lib/http.js';
import { requireAdmin } from '../middleware/auth.js';
import { gameSchema } from '../validators/gameValidators.js';

const router = Router();

router.get('/', async (_req, res) => {
  try {
    const result = await query('select * from public.games order by name');
    ok(res, result.rows);
  } catch (error) {
    fail(res, 'Failed to fetch games', 500, error.message);
  }
});

router.post('/', requireAdmin, async (req, res) => {
  const parsed = gameSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid game payload', 400, parsed.error.flatten());
  }

  try {
    const result = await query(
      `insert into public.games (name, slug, website_url, is_active, is_highlighted, notes)
       values ($1, $2, $3, $4, $5, $6)
       returning *`,
      [
        parsed.data.name,
        parsed.data.slug,
        parsed.data.website_url,
        parsed.data.is_active,
        parsed.data.is_highlighted,
        parsed.data.notes,
      ],
    );
    ok(res, result.rows[0], 201);
  } catch (error) {
    fail(res, 'Failed to create game', 500, error.message);
  }
});

router.put('/:id', requireAdmin, async (req, res) => {
  const parsed = gameSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid game payload', 400, parsed.error.flatten());
  }

  try {
    const fields = Object.entries(parsed.data);
    if (fields.length === 0) {
      return fail(res, 'No fields provided to update', 400);
    }

    const setClause = fields.map(([key], index) => `${key} = $${index + 1}`).join(', ');
    const values = fields.map(([, value]) => value);
    const result = await query(
      `update public.games set ${setClause} where id = $${fields.length + 1} returning *`,
      [...values, req.params.id],
    );
    ok(res, result.rows[0]);
  } catch (error) {
    fail(res, 'Failed to update game', 500, error.message);
  }
});

router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    await query('delete from public.games where id = $1', [req.params.id]);
    ok(res, { id: req.params.id });
  } catch (error) {
    fail(res, 'Failed to delete game', 500, error.message);
  }
});

export default router;
