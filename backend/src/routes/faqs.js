import { Router } from 'express';
import { query } from '../lib/db.js';
import { fail, ok } from '../lib/http.js';
import { faqSchema } from '../validators/gameValidators.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const search = String(req.query.q || '').trim();
    const params = [];
    let where = '';
    if (search) {
      params.push(`%${search}%`);
      where = 'where (f.question ilike $1 or f.answer ilike $1)';
    }

    const result = await query(
      `select f.*, 
              case
                when g.id is null then null
                else json_build_object('id', g.id, 'name', g.name, 'slug', g.slug)
              end as games
       from public.faqs f
       left join public.games g on g.id = f.game_id
       ${where}
       order by f.updated_at desc`,
      params,
    );
    ok(res, result.rows);
  } catch (error) {
    fail(res, 'Failed to fetch FAQs', 500, error.message);
  }
});

router.post('/', async (req, res) => {
  const parsed = faqSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid FAQ payload', 400, parsed.error.flatten());
  }

  try {
    const result = await query(
      `insert into public.faqs (game_id, question, answer, tags, approved)
       values ($1, $2, $3, $4, $5)
       returning *`,
      [
        parsed.data.game_id,
        parsed.data.question,
        parsed.data.answer,
        parsed.data.tags,
        parsed.data.approved,
      ],
    );
    ok(res, result.rows[0], 201);
  } catch (error) {
    fail(res, 'Failed to create FAQ', 500, error.message);
  }
});

router.put('/:id', async (req, res) => {
  const parsed = faqSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid FAQ payload', 400, parsed.error.flatten());
  }

  try {
    const fields = Object.entries(parsed.data);
    if (fields.length === 0) {
      return fail(res, 'No fields provided to update', 400);
    }

    const setClause = fields.map(([key], index) => `${key} = $${index + 1}`).join(', ');
    const values = fields.map(([, value]) => value);
    const result = await query(
      `update public.faqs set ${setClause} where id = $${fields.length + 1} returning *`,
      [...values, req.params.id],
    );
    ok(res, result.rows[0]);
  } catch (error) {
    fail(res, 'Failed to update FAQ', 500, error.message);
  }
});

router.delete('/:id', async (req, res) => {
  try {
    await query('delete from public.faqs where id = $1', [req.params.id]);
    ok(res, { id: req.params.id });
  } catch (error) {
    fail(res, 'Failed to delete FAQ', 500, error.message);
  }
});

export default router;
