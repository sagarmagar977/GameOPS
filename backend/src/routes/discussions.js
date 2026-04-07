import { Router } from 'express';
import { query } from '../lib/db.js';
import { fail, ok } from '../lib/http.js';
import { discussionSchema } from '../validators/gameValidators.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const search = String(req.query.q || '').trim();
    const params = [];
    let where = '';
    if (search) {
      params.push(`%${search}%`);
      where = 'where d.content ilike $1';
    }

    const result = await query(
      `select d.*,
              case
                when g.id is null then null
                else json_build_object('id', g.id, 'name', g.name, 'slug', g.slug)
              end as games
       from public.discussions d
       left join public.games g on g.id = d.game_id
       ${where}
       order by d.updated_at desc`,
      params,
    );
    ok(res, result.rows);
  } catch (error) {
    fail(res, 'Failed to fetch discussions', 500, error.message);
  }
});

router.post('/', async (req, res) => {
  const parsed = discussionSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid discussion payload', 400, parsed.error.flatten());
  }

  try {
    const result = await query(
      `insert into public.discussions (game_id, author_name, content, parent_id, approved)
       values ($1, $2, $3, $4, $5)
       returning *`,
      [
        parsed.data.game_id,
        parsed.data.author_name,
        parsed.data.content,
        parsed.data.parent_id,
        parsed.data.approved,
      ],
    );
    ok(res, result.rows[0], 201);
  } catch (error) {
    fail(res, 'Failed to create discussion', 500, error.message);
  }
});

router.put('/:id', async (req, res) => {
  const parsed = discussionSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid discussion payload', 400, parsed.error.flatten());
  }

  try {
    const fields = Object.entries(parsed.data);
    if (fields.length === 0) {
      return fail(res, 'No fields provided to update', 400);
    }

    const setClause = fields.map(([key], index) => `${key} = $${index + 1}`).join(', ');
    const values = fields.map(([, value]) => value);
    const result = await query(
      `update public.discussions set ${setClause} where id = $${fields.length + 1} returning *`,
      [...values, req.params.id],
    );
    ok(res, result.rows[0]);
  } catch (error) {
    fail(res, 'Failed to update discussion', 500, error.message);
  }
});

router.delete('/:id', async (req, res) => {
  try {
    await query('delete from public.discussions where id = $1', [req.params.id]);
    ok(res, { id: req.params.id });
  } catch (error) {
    fail(res, 'Failed to delete discussion', 500, error.message);
  }
});

export default router;
