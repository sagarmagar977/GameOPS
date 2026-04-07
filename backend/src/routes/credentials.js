import { Router } from 'express';
import { query } from '../lib/db.js';
import { fail, ok } from '../lib/http.js';
import { requireAdmin } from '../middleware/auth.js';
import { credentialSchema } from '../validators/gameValidators.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const params = [];
    let where = '';
    if (req.query.gameId) {
      params.push(req.query.gameId);
      where = 'where gc.game_id = $1';
    }

    const result = await query(
      `select gc.*, json_build_object('id', g.id, 'name', g.name, 'slug', g.slug) as games
       from public.game_credentials gc
       join public.games g on g.id = gc.game_id
       ${where}
       order by gc.is_primary desc, gc.username asc`,
      params,
    );
    ok(res, result.rows);
  } catch (error) {
    fail(res, 'Failed to fetch credentials', 500, error.message);
  }
});

router.post('/', requireAdmin, async (req, res) => {
  const parsed = credentialSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid credential payload', 400, parsed.error.flatten());
  }

  try {
    if (parsed.data.is_primary) {
      await query('update public.game_credentials set is_primary = false where game_id = $1', [
        parsed.data.game_id,
      ]);
    }

    const result = await query(
      `insert into public.game_credentials (game_id, username, password, label, is_primary, notes)
       values ($1, $2, $3, $4, $5, $6)
       returning *`,
      [
        parsed.data.game_id,
        parsed.data.username,
        parsed.data.password,
        parsed.data.label,
        parsed.data.is_primary,
        parsed.data.notes,
      ],
    );
    ok(res, result.rows[0], 201);
  } catch (error) {
    fail(res, 'Failed to create credential', 500, error.message);
  }
});

router.put('/:id', requireAdmin, async (req, res) => {
  const parsed = credentialSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid credential payload', 400, parsed.error.flatten());
  }

  try {
    if (parsed.data.is_primary && parsed.data.game_id) {
      await query('update public.game_credentials set is_primary = false where game_id = $1', [
        parsed.data.game_id,
      ]);
    }

    const fields = Object.entries(parsed.data);
    if (fields.length === 0) {
      return fail(res, 'No fields provided to update', 400);
    }

    const setClause = fields.map(([key], index) => `${key} = $${index + 1}`).join(', ');
    const values = fields.map(([, value]) => value);
    const result = await query(
      `update public.game_credentials set ${setClause} where id = $${fields.length + 1} returning *`,
      [...values, req.params.id],
    );
    ok(res, result.rows[0]);
  } catch (error) {
    fail(res, 'Failed to update credential', 500, error.message);
  }
});

router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    await query('delete from public.game_credentials where id = $1', [req.params.id]);
    ok(res, { id: req.params.id });
  } catch (error) {
    fail(res, 'Failed to delete credential', 500, error.message);
  }
});

export default router;
