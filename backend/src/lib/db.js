import { Pool } from 'pg';
import { env } from '../config/env.js';

let pool;

export function getDb() {
  // Prefer Supabase pooler connections in hosted environments like Render.
  // Direct database URLs on port 5432 can fail depending on network routing.
  const connectionString =
    env.databasePoolerUrl || env.databaseSessionPoolerUrl || env.databaseUrl;

  if (!connectionString) {
    throw new Error('Database is not configured. Add DATABASE_URL or a pooler URL.');
  }

  if (!pool) {
    pool = new Pool({
      connectionString,
      ssl: {
        rejectUnauthorized: false,
      },
    });
  }

  return pool;
}

export async function query(text, params = []) {
  const db = getDb();
  return db.query(text, params);
}
