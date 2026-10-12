# TeamOS — Project Management SaaS

A Trello/Asana-style project management app: **Vue 3 + Vite + Tailwind** frontend,
**Supabase** backend (hosted Postgres + Auth + Realtime). No custom server to run.

## Structure

```
teamos/
├── README.md          ← you are here
├── supabase/
│   ├── schema.sql     ← run FIRST in Supabase SQL editor
│   ├── seed.sql       ← run AFTER creating demo users
│   └── README.md
└── client/            ← Vue 3 app (npm install, npm run dev)
```

## Setup

### 1. Create a Supabase project
Go to [supabase.com](https://supabase.com) → New project → copy the **Project URL**
and **anon public key** (Settings → API).

### 2. Run the SQL
In the Supabase dashboard → SQL Editor:
1. Paste and run `supabase/schema.sql` (creates tables, RLS policies, triggers, realtime).
2. Create the two demo users in **Authentication → Users → Add user**:
   - `owner@teamos.test` / `password`
   - `member@teamos.test` / `password`
   - (tick "Auto Confirm User")
3. Paste and run `supabase/seed.sql` (demo team "Acme Inc", 3 projects, 14 tasks…).

### 3. Run the client
```bash
cd client
cp .env.example .env
# edit .env → VITE_SUPABASE_URL + VITE_SUPABASE_ANON_KEY
npm install
npm run dev      # dev server
npm run build    # production build → dist/
```

### 4. Log in
Use `owner@teamos.test` / `password` (or the member account).

## Demo accounts

| Email              | Password   | Role   |
|--------------------|------------|--------|
| owner@teamos.test  | password   | owner  |
| member@teamos.test | password   | member |

## Features

- **Auth** — Supabase email/password, protected routes, profiles auto-created on signup
- **Dashboard** — animated stat cards, SVG donut (tasks by status), weekly completion bars, activity feed
- **Kanban board** — 4 columns, drag-and-drop with position persistence, **live realtime updates**
- **Tasks** — create modal, slide-over drawer, subtasks checklist, comments thread, priorities, tags, due dates
- **Projects** — grid, create/edit/archive/delete
- **Team** — member list, roles (owner/admin/member), add-by-email, role management
- **Activity log** — auto-logged on task created/moved/completed/commented
- **Security** — Row Level Security: users only see their own teams' data

## Notes

- New teams must be created by an admin in the Supabase dashboard/SQL editor
  (RLS blocks client-side team creation by design — see `supabase/README.md`).
- Realtime is enabled for `tasks`, `comments`, `activities`.
