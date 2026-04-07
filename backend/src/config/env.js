import dotenv from 'dotenv';
import fs from 'node:fs';
import path from 'node:path';

const cwd = process.cwd();
const envLocalPath = path.join(cwd, '.env.local');
const envPath = path.join(cwd, '.env');

if (fs.existsSync(envLocalPath)) {
  dotenv.config({ path: envLocalPath });
} else {
  dotenv.config({ path: envPath });
}

const required = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];

for (const key of required) {
  if (key === 'SUPABASE_SERVICE_ROLE_KEY') {
    continue;
  }

  if (!process.env[key]) {
    console.warn(`[env] Missing ${key}. Some integrations may fail until it is set.`);
  }
}

export const env = {
  port: Number(process.env.PORT || 4000),
  supabaseUrl: process.env.SUPABASE_URL || '',
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  databaseUrl: process.env.DATABASE_URL || '',
  databasePoolerUrl: process.env.DATABASE_POOLER_URL || '',
  databaseSessionPoolerUrl: process.env.DATABASE_SESSION_POOLER_URL || '',
};
