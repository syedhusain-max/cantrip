-- The author's own test records, layered over the bundled library.
--
-- Why server-side rather than in the app bundle: the product's claim is
-- that prompts are known to still work. If recording "I tested this today"
-- required a rebuild and a deploy, the claim would always lag reality by a
-- release. This table lets the live app update the moment a prompt is run.
--
-- Everyone reads it; only authors write it. There is exactly one author
-- today, and hand-setting a "verified" badge is precisely the power that
-- must not leak to ordinary accounts.

alter table public.profiles
  add column if not exists is_author boolean not null default false;

create table if not exists public.author_notes (
  -- Variant ids come from the bundled library, not from a table, so this
  -- is text rather than a foreign key. A note for a variant that later
  -- disappears is harmless: the app only reads notes for prompts it has.
  variant_id text primary key,
  author_id uuid not null references auth.users (id) on delete cascade,

  -- Null means never run. Deliberately distinct from "verified long ago":
  -- one is unknown, the other is stale, and conflating them is how a
  -- library starts lying.
  tested_on date,
  tested_model_label text,

  -- "Works on v6.1, fails on v7" is the most useful single fact about a
  -- prompt and has nowhere else to live.
  works_on text[] not null default '{}',
  fails_on text[] not null default '{}',

  best_in_tool_id text,

  verdict text not null default 'untested'
    check (verdict in ('untested', 'works', 'broken', 'worksWithCaveats')),

  note text check (note is null or length(note) <= 2000),

  -- Editorial, and labelled as such in the UI. Never presented as a
  -- community verdict — popularity badges are computed from real signal
  -- counts, never set by hand, because a hand-set "popular" badge is a
  -- fabricated testimonial.
  creators_choice boolean not null default false,
  red_flag boolean not null default false,

  updated_at timestamptz not null default now()
);

create index if not exists author_notes_verdict_idx
  on public.author_notes (verdict);

alter table public.author_notes enable row level security;
alter table public.author_notes force row level security;

-- Readable by everyone, including signed-out visitors: a verification
-- nobody can see is worth nothing.
create policy author_notes_public_read on public.author_notes
  for select
  to anon, authenticated
  using (true);

-- Written only by accounts flagged as authors. The check runs on both
-- using and with check so an author cannot write a row attributed to
-- someone else.
create policy author_notes_author_write on public.author_notes
  for all
  to authenticated
  using (
    (select auth.uid()) = author_id
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_author
    )
  )
  with check (
    (select auth.uid()) = author_id
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_author
    )
  );

create or replace function public.touch_author_note()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists author_notes_touch on public.author_notes;
create trigger author_notes_touch
  before update on public.author_notes
  for each row execute function public.touch_author_note();
