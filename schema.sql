-- Debt Tracker — database schema
--
-- Run this once in your Supabase project: SQL Editor → New query → paste → Run.
-- Safe to re-run; every statement is guarded.
--
-- The security model: one row per user, and row-level security policies that
-- compare auth.uid() to the row's user_id. The database itself refuses to
-- return or modify another account's row, so a bug in the frontend cannot leak
-- one user's finances to another. This is the guarantee localStorage never had.

-- ── Table ───────────────────────────────────────────────────────────────────
-- The whole tracker is stored as one JSON document, mirroring the app's single
-- state object. That keeps the sync layer trivial (read one row, write one row)
-- and means adding a field to the app needs no migration. If cross-user queries
-- are ever needed (aggregates, sharing), this normalizes into real tables then.

create table if not exists public.trackers (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

comment on table public.trackers is
  'One tracker document per user. Access is restricted to the owner by RLS.';

-- ── Row-level security ──────────────────────────────────────────────────────
-- Without this, the anon key could read every row. With it, the anon key can
-- only ever reach the signed-in user''s own row.

alter table public.trackers enable row level security;

-- Policies are dropped first so this file stays re-runnable.
drop policy if exists "read own tracker"   on public.trackers;
drop policy if exists "insert own tracker" on public.trackers;
drop policy if exists "update own tracker" on public.trackers;
drop policy if exists "delete own tracker" on public.trackers;

create policy "read own tracker"
  on public.trackers for select
  using (auth.uid() = user_id);

create policy "insert own tracker"
  on public.trackers for insert
  with check (auth.uid() = user_id);

-- Both clauses matter: USING controls which rows you may target, WITH CHECK
-- stops you rewriting user_id to hand the row to someone else.
create policy "update own tracker"
  on public.trackers for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "delete own tracker"
  on public.trackers for delete
  using (auth.uid() = user_id);

-- ── updated_at ──────────────────────────────────────────────────────────────
-- Maintained by the database rather than the client, so it stays honest even if
-- a client sends a stale value. Used for last-write-wins across devices.

-- search_path is pinned empty so the function can only resolve built-ins
-- (now() lives in pg_catalog, which is always searched).
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trackers_touch_updated_at on public.trackers;

create trigger trackers_touch_updated_at
  before update on public.trackers
  for each row execute function public.touch_updated_at();

-- ── Auto-provision a row on signup ──────────────────────────────────────────
-- Guarantees every account has exactly one tracker row from the moment it
-- exists, so the app never has to branch on "row missing".
-- SECURITY DEFINER is required: this runs as the auth system inserting on
-- behalf of a user who is not yet authenticated in this transaction.

create or replace function public.provision_tracker()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.trackers (user_id, data)
  values (new.id, '{}'::jsonb)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.provision_tracker();

-- ── Lock down direct execution ──────────────────────────────────────────────
-- Postgres grants EXECUTE on new functions to PUBLIC, and Supabase exposes
-- public-schema functions as /rest/v1/rpc endpoints. These are trigger-only,
-- so no API role should be able to call them. Triggers still fire: EXECUTE is
-- checked when the trigger is created, not each time it runs.

revoke execute on function public.provision_tracker() from public, anon, authenticated;
revoke execute on function public.touch_updated_at()  from public, anon, authenticated;
