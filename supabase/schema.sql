create extension if not exists "pgcrypto";

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  website_url text not null default '',
  is_active boolean not null default true,
  is_highlighted boolean not null default false,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.game_credentials (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  username text not null,
  password text not null,
  label text not null default '',
  is_primary boolean not null default false,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cashout_rules (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null unique references public.games(id) on delete cascade,
  freeplay_label text not null default '',
  payout_min numeric(12, 2) not null default 0,
  payout_max numeric(12, 2) not null default 0,
  slope_percent numeric(5, 2) not null default 0,
  is_freeplay_enabled boolean not null default true,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cashouts (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  credential_id uuid references public.game_credentials(id) on delete set null,
  player_name text not null,
  amount numeric(12, 2) not null,
  status text not null default 'pending',
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.faqs (
  id uuid primary key default gen_random_uuid(),
  game_id uuid references public.games(id) on delete set null,
  question text not null,
  answer text not null,
  tags text[] not null default '{}',
  approved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.discussions (
  id uuid primary key default gen_random_uuid(),
  game_id uuid references public.games(id) on delete set null,
  author_name text not null,
  content text not null,
  parent_id uuid references public.discussions(id) on delete cascade,
  approved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.automation_tasks (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  credential_id uuid references public.game_credentials(id) on delete set null,
  action text not null,
  username text not null,
  status text not null default 'queued',
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists games_set_updated_at on public.games;
create trigger games_set_updated_at
before update on public.games
for each row execute function public.set_updated_at();

drop trigger if exists game_credentials_set_updated_at on public.game_credentials;
create trigger game_credentials_set_updated_at
before update on public.game_credentials
for each row execute function public.set_updated_at();

drop trigger if exists cashout_rules_set_updated_at on public.cashout_rules;
create trigger cashout_rules_set_updated_at
before update on public.cashout_rules
for each row execute function public.set_updated_at();

drop trigger if exists faqs_set_updated_at on public.faqs;
create trigger faqs_set_updated_at
before update on public.faqs
for each row execute function public.set_updated_at();

drop trigger if exists discussions_set_updated_at on public.discussions;
create trigger discussions_set_updated_at
before update on public.discussions
for each row execute function public.set_updated_at();
