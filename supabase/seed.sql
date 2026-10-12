-- ============================================================================
-- TeamOS — demo seed data
-- Run this file AFTER schema.sql in the Supabase SQL editor (project owner).
--
-- PREREQUISITE: two auth users must already exist:
--   * owner@teamos.test
--   * member@teamos.test
-- Create them first in Supabase Dashboard → Authentication → Users
-- (any password works). This file does NOT create auth users itself —
-- if either user is missing it aborts with a NOTICE telling you why.
--
-- Seeds: 1 team ("Acme Inc"), 3 projects, 14 tasks, 9 subtasks,
--        4 comments, 8 activity rows. Timestamps are relative to now().
-- ============================================================================

do $$
declare
  owner_id  uuid;
  member_id uuid;
  team_id   uuid := gen_random_uuid();
  p_web     uuid := gen_random_uuid();
  p_mob     uuid := gen_random_uuid();
  p_mkt     uuid := gen_random_uuid();
  t1  uuid := gen_random_uuid();
  t2  uuid := gen_random_uuid();
  t3  uuid := gen_random_uuid();
  t4  uuid := gen_random_uuid();
  t5  uuid := gen_random_uuid();
  t6  uuid := gen_random_uuid();
  t7  uuid := gen_random_uuid();
  t8  uuid := gen_random_uuid();
  t9  uuid := gen_random_uuid();
  t10 uuid := gen_random_uuid();
  t11 uuid := gen_random_uuid();
  t12 uuid := gen_random_uuid();
  t13 uuid := gen_random_uuid();
  t14 uuid := gen_random_uuid();
begin
  -- --------------------------------------------------------------------------
  -- 1. Look up the two demo auth users.
  -- --------------------------------------------------------------------------
  select id into owner_id  from auth.users where email = 'owner@teamos.test';
  select id into member_id from auth.users where email = 'member@teamos.test';

  if owner_id is null or member_id is null then
    raise notice 'SEED ABORTED: could not find auth.users with emails ''owner@teamos.test'' and ''member@teamos.test''. Create both users first in Supabase Dashboard → Authentication → Users, then re-run this file.';
    return;
  end if;

  -- --------------------------------------------------------------------------
  -- 2. Team + membership.
  -- --------------------------------------------------------------------------
  insert into public.teams (id, name, slug, created_at, updated_at)
    values (team_id, 'Acme Inc', 'acme-inc',
            now() - interval '10 days', now() - interval '10 days');

  insert into public.team_members (team_id, user_id, role, created_at)
    values
      (team_id, owner_id,  'owner',  now() - interval '10 days'),
      (team_id, member_id, 'member', now() - interval '10 days');

  -- Friendly display names on the profiles the signup trigger auto-created.
  update public.profiles set name = 'Ava Owner',  avatar_color = '#7c6cf0' where id = owner_id;
  update public.profiles set name = 'Ben Member', avatar_color = '#22d3ee' where id = member_id;

  -- --------------------------------------------------------------------------
  -- 3. Projects.
  -- --------------------------------------------------------------------------
  insert into public.projects (id, team_id, name, key, description, color, position, created_at, updated_at)
    values
      (p_web, team_id, 'Website Redesign', 'WEB',
       'Full refresh of the Acme marketing website.', '#7c6cf0', 0,
       now() - interval '9 days', now() - interval '9 days'),
      (p_mob, team_id, 'Mobile App', 'MOB',
       'Native-feel companion app for customers.', '#22d3ee', 1,
       now() - interval '8 days', now() - interval '8 days'),
      (p_mkt, team_id, 'Marketing Site', 'MKT',
       'Campaign pages and content experiments.', '#f472b6', 2,
       now() - interval '7 days', now() - interval '7 days');

  -- --------------------------------------------------------------------------
  -- 4. Tasks (14) — spread across all four statuses, varied priorities.
  --    `position` is ordered 0..n within each (project, status) column.
  -- --------------------------------------------------------------------------
  insert into public.tasks
    (id, project_id, title, description, status, priority, assignee_id, due_date,
     tags, position, created_by, completed_at, created_at, updated_at)
    values
      -- Website Redesign (WEB)
      (t1, p_web, 'Design homepage hero',
       'New hero section with product shots and a clear CTA.',
       'in_progress', 'high', owner_id, (now() + interval '5 days')::date,
       array['design','homepage'], 0, owner_id, null,
       now() - interval '6 days', now() - interval '1 day'),
      (t2, p_web, 'Implement responsive navbar',
       'Sticky nav with mobile drawer menu.',
       'backlog', 'medium', member_id, (now() + interval '10 days')::date,
       array['frontend'], 0, owner_id, null,
       now() - interval '6 days', now() - interval '6 days'),
      (t3, p_web, 'Write copy for landing page',
       'Headline, subcopy and three feature blurbs.',
       'review', 'low', member_id, (now() - interval '1 day')::date,
       array['copy'], 0, member_id, null,
       now() - interval '5 days', now() - interval '2 days'),
      (t4, p_web, 'Set up analytics',
       'GA4 property with conversion events.',
       'done', 'medium', owner_id, (now() - interval '5 days')::date,
       array['analytics'], 0, owner_id, now() - interval '2 days',
       now() - interval '8 days', now() - interval '2 days'),
      (t5, p_web, 'Fix footer links',
       'Three footer links return 404s after the sitemap change.',
       'backlog', 'urgent', null, (now() + interval '2 days')::date,
       array['bug'], 1, member_id, null,
       now() - interval '4 days', now() - interval '4 days'),

      -- Mobile App (MOB)
      (t6, p_mob, 'Onboarding flow screens',
       'Five-step onboarding: welcome, permissions, profile, tour, done.',
       'in_progress', 'high', member_id, (now() + interval '7 days')::date,
       array['ui','ux'], 0, member_id, null,
       now() - interval '6 days', now() - interval '1 day'),
      (t7, p_mob, 'Push notification setup',
       'APNs + FCM credentials and topic subscriptions.',
       'backlog', 'medium', owner_id, (now() + interval '14 days')::date,
       array['backend'], 0, owner_id, null,
       now() - interval '5 days', now() - interval '5 days'),
      (t8, p_mob, 'App store screenshots',
       '6.5" and 5.5" screenshot sets for both stores.',
       'review', 'medium', member_id, (now() + interval '3 days')::date,
       array['release'], 0, member_id, null,
       now() - interval '4 days', now() - interval '1 day'),
      (t9, p_mob, 'Login with Apple',
       'Sign in with Apple wired into the auth flow.',
       'done', 'high', owner_id, (now() - interval '6 days')::date,
       array['auth'], 0, owner_id, now() - interval '4 days',
       now() - interval '9 days', now() - interval '4 days'),

      -- Marketing Site (MKT)
      (t10, p_mkt, 'Blog post: launch announcement',
       '1200-word launch post with product screenshots.',
       'backlog', 'low', member_id, (now() + interval '12 days')::date,
       array['content'], 0, member_id, null,
       now() - interval '5 days', now() - interval '5 days'),
      (t11, p_mkt, 'SEO meta tags audit',
       'Check titles, descriptions and OG tags on all pages.',
       'in_progress', 'medium', owner_id, (now() + interval '6 days')::date,
       array['seo'], 0, owner_id, null,
       now() - interval '4 days', now() - interval '2 days'),
      (t12, p_mkt, 'Email drip campaign',
       'Three-email welcome sequence for new signups.',
       'done', 'medium', member_id, (now() - interval '3 days')::date,
       array['email'], 0, member_id, now() - interval '1 day',
       now() - interval '7 days', now() - interval '1 day'),
      (t13, p_mkt, 'Hero video for homepage',
       '45-second product overview video.',
       'review', 'high', owner_id, (now() + interval '4 days')::date,
       array['video'], 0, owner_id, null,
       now() - interval '3 days', now() - interval '5 hours'),
      (t14, p_mkt, 'Update pricing page',
       'New tiers and FAQ section.',
       'backlog', 'medium', null, (now() + interval '9 days')::date,
       array['content'], 1, member_id, null,
       now() - interval '2 days', now() - interval '2 days');

  -- --------------------------------------------------------------------------
  -- 5. Subtasks (9) — mixed done states.
  -- --------------------------------------------------------------------------
  insert into public.subtasks (task_id, title, done, position, created_at)
    values
      (t1,  'Draft 3 layout options', true,  0, now() - interval '5 days'),
      (t1,  'Pick final imagery',     false, 1, now() - interval '5 days'),
      (t6,  'Wireframe screens',      true,  0, now() - interval '5 days'),
      (t6,  'Prototype in Figma',     false, 1, now() - interval '4 days'),
      (t4,  'Add GA4 snippet',        true,  0, now() - interval '7 days'),
      (t4,  'Verify events fire',     true,  1, now() - interval '6 days'),
      (t12, 'Write email 1',          true,  0, now() - interval '6 days'),
      (t12, 'Write email 2',          true,  1, now() - interval '5 days'),
      (t12, 'Schedule sends',         false, 2, now() - interval '4 days');

  -- --------------------------------------------------------------------------
  -- 6. Comments (4).
  -- --------------------------------------------------------------------------
  insert into public.comments (task_id, user_id, body, created_at)
    values
      (t1, member_id,
       'First draft is ready for review — the Figma link is in the description.',
       now() - interval '1 day'),
      (t1, owner_id,
       'Looks great. One tweak: make the CTA button bigger on mobile.',
       now() - interval '20 hours'),
      (t6, owner_id,
       'Let''s aim to finish onboarding before Friday.',
       now() - interval '2 days'),
      (t13, member_id,
       'Video draft exported, uploading now.',
       now() - interval '5 hours');

  -- --------------------------------------------------------------------------
  -- 7. Activities (8).
  -- --------------------------------------------------------------------------
  insert into public.activities (team_id, user_id, action, subject_type, subject_id, meta, created_at)
    values
      (team_id, owner_id, 'project.created', 'project', p_web,
       '{"project_name": "Website Redesign", "project_key": "WEB"}'::jsonb,
       now() - interval '9 days'),
      (team_id, owner_id, 'project.created', 'project', p_mob,
       '{"project_name": "Mobile App", "project_key": "MOB"}'::jsonb,
       now() - interval '8 days'),
      (team_id, owner_id, 'task.created', 'task', t1,
       '{"task_title": "Design homepage hero", "project_key": "WEB"}'::jsonb,
       now() - interval '6 days'),
      (team_id, member_id, 'task.created', 'task', t6,
       '{"task_title": "Onboarding flow screens", "project_key": "MOB"}'::jsonb,
       now() - interval '6 days'),
      (team_id, owner_id, 'task.moved', 'task', t9,
       '{"task_title": "Login with Apple", "from": "review", "to": "done"}'::jsonb,
       now() - interval '4 days'),
      (team_id, member_id, 'task.moved', 'task', t1,
       '{"task_title": "Design homepage hero", "from": "backlog", "to": "in_progress"}'::jsonb,
       now() - interval '3 days'),
      (team_id, owner_id, 'task.completed', 'task', t4,
       '{"task_title": "Set up analytics", "project_key": "WEB"}'::jsonb,
       now() - interval '2 days'),
      (team_id, member_id, 'task.commented', 'task', t1,
       '{"task_title": "Design homepage hero"}'::jsonb,
       now() - interval '1 day');

  raise notice 'Seed complete: 1 team, 3 projects, 14 tasks, 9 subtasks, 4 comments, 8 activities.';
end $$;
