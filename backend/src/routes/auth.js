import { Router } from 'express';
import { env } from '../config/env.js';
import { hashPassword, signAuthToken, verifyPassword } from '../lib/auth.js';
import { query } from '../lib/db.js';
import { fail, ok } from '../lib/http.js';
import { authenticate } from '../middleware/auth.js';
import { loginSchema, registerSchema } from '../validators/authValidators.js';

const router = Router();

function mapUser(row) {
  return {
    id: row.id,
    email: row.email,
    role: row.role,
  };
}

function buildAuthResponse(row) {
  const user = mapUser(row);

  return {
    token: signAuthToken(user),
    user,
  };
}

router.post('/register', async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid registration payload', 400, parsed.error.flatten());
  }

  const email = parsed.data.email.trim().toLowerCase();

  try {
    const existing = await query('select id from public.app_users where lower(email) = $1', [email]);
    if (existing.rowCount > 0) {
      return fail(res, 'An account with this email already exists', 409);
    }

    const result = await query(
      `insert into public.app_users (email, password_hash, role)
       values ($1, $2, 'operator')
       returning id, email, role`,
      [email, hashPassword(parsed.data.password)],
    );

    return ok(res, buildAuthResponse(result.rows[0]), 201);
  } catch (error) {
    return fail(res, 'Failed to create account', 500, error.message);
  }
});

router.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'Invalid login payload', 400, parsed.error.flatten());
  }

  const email = parsed.data.email.trim().toLowerCase();

  try {
    const result = await query(
      `select id, email, password_hash, role
       from public.app_users
       where lower(email) = $1
       limit 1`,
      [email],
    );

    if (result.rowCount === 0) {
      return fail(res, 'Wrong email or password', 401);
    }

    const user = result.rows[0];
    if (!verifyPassword(parsed.data.password, user.password_hash)) {
      return fail(res, 'Wrong email or password', 401);
    }

    return ok(res, buildAuthResponse(user));
  } catch (error) {
    return fail(res, 'Failed to log in', 500, error.message);
  }
});

router.get('/me', authenticate, async (req, res) => {
  try {
    const result = await query(
      `select id, email, role
       from public.app_users
       where id = $1
       limit 1`,
      [req.user.sub],
    );

    if (result.rowCount === 0) {
      return fail(res, 'User not found', 404);
    }

    return ok(res, mapUser(result.rows[0]));
  } catch (error) {
    return fail(res, 'Failed to load current user', 500, error.message);
  }
});

router.get('/bootstrap-admin', (_req, res) => {
  return ok(res, {
    email: env.adminEmail,
    note: 'This admin user is seeded when you run the migration script.',
  });
});

export default router;
