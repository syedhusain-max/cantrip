-- Who is on which tier.
--
-- One row per account, created on sign-up by a trigger so the app never has
-- to insert it. The client can read its own row and nothing else: an app
-- that can write its own entitlement doesn't have one. Writes come from the
-- billing webhook using the service role, which bypasses RLS.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  -- Null means free. A timestamp in the future means Pro until then, which
  -- makes expiry the absence of a renewal rather than an event someone has
  -- to remember to fire.
  pro_until timestamptz,
  -- Which store the subscription came from, so a support question can be
  -- answered without guessing.
  billing_source text check (billing_source in ('play', 'stripe')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.profiles force row level security;

-- Select only. No insert, update or delete policy exists for users, so
-- those are denied by default — deliberately, not by oversight.
create policy profiles_read_own on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

-- Create the row with the account, so every signed-in user has one.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
