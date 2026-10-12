-- ============================================================================
-- TeamOS — Supabase backend schema
-- Run this file FIRST in the Supabase SQL editor (as the project owner).
-- Re-runnable: the DROP section below resets everything to a clean slate,
-- so running it twice gives you the same result, not duplicate objects.
-- Requires the pgcrypto extension for gen_random_uuid().
-- No custom server needed — the Vue 3 client talks to Supabase directly.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Extension
-- ----------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. Clean slate (drop in dependency order: children before parents)
--    Table drops use CASCADE so dependent policies/triggers go with them.
-- ----------------------------------------------------------------------------

-- Trigger on auth.users + trigger functions first (auth.users itself stays).
drop trigger if exists on_new_user on auth.users;
drop function if exists public.handle_new_user();
drop function if exists public.touch_updated_at();

drop table if exists public.activities cascade;
drop table if exists public.comments cascade;
drop table if exists public.subtasks cascade;
drop table if exists public.tasks cascade;
drop table if exists public.projects cascade;
drop table if exists public.team_members cascade;
drop table if exists public.teams cascade;
drop table if exists public.profiles cascade;

-- RLS helper functions (in case a previous run defined them standalone).
drop function if exists public.is_team_member(uuid);
drop function if exists public.team_role(uuid);
drop function if exists public.is_team_admin(uuid);
drop function if exists public.project_team(uuid);
drop function if exists public.task_team(uuid);

-- ----------------------------------------------------------------------------
-- 2. Tables — contract-exact definitions. Do not rename anything:
--    the Vue 3 client is coded against these exact table/column names.
-- ----------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  avatar_color text default '#7c6cf0',
  created_at timestamptz default now()
);

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  created_at timestamptz default now(),
  unique (team_id, user_id)
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  name text not null,
  key text not null,
  description text,
  color text not null default '#7c6cf0',
  status text not null default 'active' check (status in ('active','archived')),
  position int not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (team_id, key)
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  description text,
  status text not null default 'backlog' check (status in ('backlog','in_progress','review','done')),
  priority text not null default 'medium' check (priority in ('low','medium','high','urgent')),
  assignee_id uuid references auth.users(id) on delete set null,
  due_date date,
  tags text[] not null default '{}',
  position int not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  completed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.subtasks (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  title text not null,
  done boolean not null default false,
  position int not null default 0,
  created_at timestamptz default now()
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz default now()
);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  subject_type text,
  subject_id uuid,
  meta jsonb not null default '{}',
  created_at timestamptz default now()
);

-- ----------------------------------------------------------------------------
-- 3. Indexes
-- ----------------------------------------------------------------------------
create index idx_team_members_team_id on public.team_members (team_id);
create index idx_team_members_user_id on public.team_members (user_id);
create index idx_projects_team_id on public.projects (team_id);
create index idx_tasks_project_id on public.tasks (project_id);
create index idx_tasks_status on public.tasks (status);
create index idx_tasks_assignee_id on public.tasks (assignee_id);
create index idx_subtasks_task_id on public.subtasks (task_id);
create index idx_comments_task_id on public.comments (task_id);
create index idx_activities_team_created on public.activities (team_id, created_at desc);

-- ----------------------------------------------------------------------------
-- 4. Trigger functions
-- ----------------------------------------------------------------------------

-- Auto-create a profile row whenever a new auth user signs up.
-- name = part of the email before '@', first letter capitalized.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    new.email,
    initcap(split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- NOTE: creating a trigger on auth.users requires project-owner privileges
-- (the Supabase SQL editor runs as postgres, so this works there).
drop trigger if exists on_new_user on auth.users;
create trigger on_new_user
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Auto-touch updated_at on update.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_updated_at on public.teams;
create trigger set_updated_at
  before update on public.teams
  for each row execute function public.touch_updated_at();

drop trigger if exists set_updated_at on public.projects;
create trigger set_updated_at
  before update on public.projects
  for each row execute function public.touch_updated_at();

drop trigger if exists set_updated_at on public.tasks;
create trigger set_updated_at
  before update on public.tasks
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------------------------------
-- 5. SECURITY DEFINER helper functions for RLS (set search_path = public)
-- ----------------------------------------------------------------------------

create or replace function public.is_team_member(tid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.team_members
    where team_id = tid
      and user_id = auth.uid()
  );
$$;

create or replace function public.team_role(tid uuid)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select role
  from public.team_members
  where team_id = tid
    and user_id = auth.uid()
  limit 1;
$$;

create or replace function public.is_team_admin(tid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select public.team_role(tid) in ('owner', 'admin');
$$;

create or replace function public.project_team(pid uuid)
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select team_id
  from public.projects
  where id = pid;
$$;

create or replace function public.task_team(tid uuid)
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select p.team_id
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = tid;
$$;

-- ----------------------------------------------------------------------------
-- 6. Row Level Security — enable on ALL tables, then policies for `authenticated`
--    (service_role bypasses RLS automatically — no policy needed for it.)
-- ----------------------------------------------------------------------------
alter table public.profiles      enable row level security;
alter table public.teams         enable row level security;
alter table public.team_members  enable row level security;
alter table public.projects      enable row level security;
alter table public.tasks         enable row level security;
alter table public.subtasks      enable row level security;
alter table public.comments      enable row level security;
alter table public.activities    enable row level security;

-- teams: members can read/create, only admins can update/delete.
create policy "teams_select" on public.teams
  for select to authenticated
  using (public.is_team_member(id));
create policy "teams_insert" on public.teams
  for insert to authenticated
  with check (public.is_team_member(id));
create policy "teams_update" on public.teams
  for update to authenticated
  using (public.is_team_admin(id));
create policy "teams_delete" on public.teams
  for delete to authenticated
  using (public.is_team_admin(id));

-- team_members: members can read the roster, only admins can change it.
create policy "team_members_select" on public.team_members
  for select to authenticated
  using (public.is_team_member(team_id));
create policy "team_members_insert" on public.team_members
  for insert to authenticated
  with check (public.is_team_admin(team_id));
create policy "team_members_update" on public.team_members
  for update to authenticated
  using (public.is_team_admin(team_id));
create policy "team_members_delete" on public.team_members
  for delete to authenticated
  using (public.is_team_admin(team_id));

-- profiles: you can always read yourself; you can read other users only if
-- you share at least one team with them (co-member check via self-join).
-- You can only update your own profile.
create policy "profiles_select" on public.profiles
  for select to authenticated
  using (
    id = auth.uid()
    or exists (
      select 1
      from public.team_members tm1
      join public.team_members tm2 on tm2.team_id = tm1.team_id
      where tm1.user_id = auth.uid()
        and tm2.user_id = profiles.id
    )
  );
create policy "profiles_update" on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
-- NOTE: no INSERT/DELETE policy for clients — rows are created by the
-- security-definer handle_new_user() trigger, which bypasses RLS.

-- projects: full access for team members.
create policy "projects_all" on public.projects
  for all to authenticated
  using (public.is_team_member(team_id));

-- tasks: full access for members of the task's team.
create policy "tasks_all" on public.tasks
  for all to authenticated
  using (public.is_team_member(public.task_team(project_id)));

-- subtasks: full access for members of the parent task's team.
create policy "subtasks_all" on public.subtasks
  for all to authenticated
  using (public.is_team_member(public.task_team(task_id)));

-- comments: read/insert/update for team members; delete only your own.
create policy "comments_select" on public.comments
  for select to authenticated
  using (public.is_team_member(public.task_team(task_id)));
create policy "comments_insert" on public.comments
  for insert to authenticated
  with check (public.is_team_member(public.task_team(task_id)));
create policy "comments_update" on public.comments
  for update to authenticated
  using (public.is_team_member(public.task_team(task_id)));
create policy "comments_delete" on public.comments
  for delete to authenticated
  using (
    user_id = auth.uid()
    and public.is_team_member(public.task_team(task_id))
  );

-- activities: members can read and write the feed; no client update/delete.
create policy "activities_select" on public.activities
  for select to authenticated
  using (public.is_team_member(team_id));
create policy "activities_insert" on public.activities
  for insert to authenticated
  with check (public.is_team_member(team_id));

-- ----------------------------------------------------------------------------
-- 7. Grants — RLS policies are useless without base table privileges.
-- ----------------------------------------------------------------------------
grant select, insert, update, delete
  on public.profiles, public.teams, public.team_members, public.projects,
     public.tasks, public.subtasks, public.comments, public.activities
  to authenticated;

grant execute
  on function public.is_team_member(uuid),
     public.team_role(uuid),
     public.is_team_admin(uuid),
     public.project_team(uuid),
     public.task_team(uuid)
  to authenticated;

-- ----------------------------------------------------------------------------
-- 8. Realtime — guard each ADD so re-running the file is idempotent.
--    (Requires the supabase_realtime publication, standard on Supabase.)
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'tasks'
  ) then
    alter publication supabase_realtime add table public.tasks;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'comments'
  ) then
    alter publication supabase_realtime add table public.comments;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'activities'
  ) then
    alter publication supabase_realtime add table public.activities;
  end if;
end $$;
