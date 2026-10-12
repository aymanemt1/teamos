# TeamOS — Supabase Backend

No custom server. The Vue 3 client talks to Supabase directly (PostgREST + Realtime). These two SQL files are everything the backend needs.

## Files

| File | Purpose |
|---|---|
| `schema.sql` | Extension, all 8 tables (contract-exact), indexes, `handle_new_user` signup trigger, `updated_at` triggers, SECURITY DEFINER RLS helpers, RLS policies on every table, grants, Realtime publication setup. |
| `seed.sql` | Demo data: 1 team ("Acme Inc"), 3 projects, 14 tasks, 9 subtasks, 4 comments, 8 activity rows, with timestamps relative to `now()`. |

## Run order

1. In the Supabase Dashboard, open the **SQL editor** (run as the project owner — some statements, like the trigger on `auth.users`, need owner privileges).
2. Paste and run **`schema.sql`** first. It is re-runnable: the DROP section at the top resets everything to a clean slate.
3. Create the demo auth users in **Authentication → Users**:
   - `owner@teamos.test` (any password)
   - `member@teamos.test` (any password)

   Signing up (or creating) these users fires the `handle_new_user` trigger, which auto-creates their `profiles` rows (name = part before `@`, capitalized: "Owner" / "Member").
4. Paste and run **`seed.sql`**. It looks both users up by email; if either is missing it aborts with a `NOTICE` telling you to create them first (it never fabricates auth users).

## Demo accounts

| Email | Role in "Acme Inc" | Profile name | Avatar color |
|---|---|---|---|
| `owner@teamos.test` | `owner` | Ava Owner | `#7c6cf0` (violet) |
| `member@teamos.test` | `member` | Ben Member | `#22d3ee` (cyan) |

Seeded projects: **Website Redesign** (`WEB`, violet), **Mobile App** (`MOB`, cyan), **Marketing Site** (`MKT`, pink) — all `active`, with tasks spread across `backlog` / `in_progress` / `review` / `done`.

## Notes for the client

- **RLS** is enabled on all tables. `service_role` bypasses RLS automatically (no policy needed); the `authenticated` role gets team-scoped access via the helper functions (`is_team_member`, `is_team_admin`, `project_team`, `task_team`).
- **Team bootstrapping:** the `teams` INSERT policy requires `is_team_member(id)`, so a brand-new team can't be created by a bare client insert alone. Create the team first (SQL editor / service_role), then insert the creator into `team_members` — exactly what `seed.sql` does.
- **Realtime:** `tasks`, `comments`, and `activities` are added to the `supabase_realtime` publication (guarded with `IF NOT EXISTS` checks so re-runs are safe). Enable Realtime on those tables in the client as usual.
- **Comments:** team members can read/add/edit comments; only the author can delete their own (`user_id = auth.uid()`).
- **Activities:** read/insert for members; no client update/delete.
