import { fail } from '../lib/http.js';
import { verifyAuthToken } from '../lib/auth.js';

export function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) {
    return fail(res, 'Authentication required', 401);
  }

  const token = header.slice('Bearer '.length).trim();

  try {
    req.user = verifyAuthToken(token);
    return next();
  } catch (_error) {
    return fail(res, 'Invalid or expired token', 401);
  }
}

export function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') {
    return fail(res, 'Admin access required', 403);
  }

  return next();
}
