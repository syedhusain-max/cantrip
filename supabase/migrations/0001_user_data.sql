-- Cantrip user data.
--
-- The prompt library itself is NOT here: it ships in the app bundle, so this
-- database only ever holds what a user did — what they saved, organised and
-- reported. That keeps the backend small, cheap and free of content-approval
-- machinery.
--
-- Row ids (folders.id, forks.id) are generated on the client and are only
-- unique per user, so every primary key is (user_id, id). That lets a client
-- create a folder offline and sync it later without asking the server for an
-- id first.

create table if not exists public.favourites (
  user_id uuid not null references auth.users (id) on delete cascade,
  variant_id text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, variant_id)
);

-- One row per prompt the user has reported on. Their own verdict only: the
-- community totals shown in the app come from the bundled content, so this
-- table never needs a public read path.
create table if not exists public.signals (
  user_id uuid not null references auth.users (id) on delete cascade,
  variant_id text not null,
  works boolean not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, variant_id)
);

create table if not exists public.folders (
  user_id uuid not null references auth.users (id) on delete cascade,
  id text not null,
  name text not null check (length(name) between 1 and 200),
  type text not null default 'personal' check (type in ('personal', 'client')),
  -- Folder-level variable defaults: set a client's brand colour once and
  -- every prompt saved into the folder pre-fills from it.
  variable_defaults jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (user_id, id)
);

-- A saved copy: a reference to a library prompt plus the user's overrides,
-- never a copy of the prompt text. If the library version changes, the saved
-- copy can say so (source_verified_on is what it compares against).
create table if not exists public.forks (
  user_id uuid not null references auth.users (id) on delete cascade,
  id text not null,
  folder_id text not null,
  source_variant_id text not null,
  title text check (title is null or length(title) between 1 and 300),
  -- "values" is a reserved word in SQL, hence the name.
  filled_values jsonb not null default '{}'::jsonb,
  source_verified_on date not null,
  created_at timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, folder_id)
    references public.folders (user_id, id) on delete cascade
);

-- Deleting a folder cascades to its forks through this foreign key, and the
-- app lists forks by folder, so the FK columns need their own index: a
-- composite primary key only serves lookups that start at its first column.
create index if not exists forks_folder_idx
  on public.forks (user_id, folder_id);

alter table public.favourites enable row level security;
alter table public.signals enable row level security;
alter table public.folders enable row level security;
alter table public.forks enable row level security;

alter table public.favourites force row level security;
alter table public.signals force row level security;
alter table public.folders force row level security;
alter table public.forks force row level security;

-- Every table is single-tenant by row. auth.uid() is wrapped in a select so
-- Postgres evaluates it once per query rather than once per row.
create policy favourites_owner on public.favourites
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy signals_owner on public.signals
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy folders_owner on public.folders
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy forks_owner on public.forks
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
