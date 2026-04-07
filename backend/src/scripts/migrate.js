import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { getDb } from '../lib/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const schemaPath = path.resolve(__dirname, '../../../supabase/schema.sql');

async function run() {
  const sql = await fs.readFile(schemaPath, 'utf8');
  const db = getDb();
  await db.query(sql);
  console.log('Migration completed successfully.');
  await db.end();
}

run().catch((error) => {
  console.error('Migration failed:', error.message);
  process.exitCode = 1;
});
