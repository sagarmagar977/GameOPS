import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { env } from '../config/env.js';
import { hashPassword } from '../lib/auth.js';
import { getDb } from '../lib/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const schemaPath = path.resolve(__dirname, '../../../supabase/schema.sql');

async function run() {
  const sql = await fs.readFile(schemaPath, 'utf8');
  const db = getDb();
  await db.query(sql);
  await db.query(
    `insert into public.app_users (email, password_hash, role)
     values ($1, $2, 'admin')
     on conflict (email) do update set role = excluded.role`,
    [env.adminEmail, hashPassword(env.adminPassword)],
  );
  console.log('Migration completed successfully.');
  await db.end();
}

run().catch((error) => {
  console.error('Migration failed:', error.message);
  process.exitCode = 1;
});
