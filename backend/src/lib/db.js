import { Pool } from 'pg';
import { env } from '../config/env.js';

let pool;

export function getDb() {
  const connectionString = env.databaseUrl || env.databaseSessionPoolerUrl || env.databasePoolerUrl;

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
