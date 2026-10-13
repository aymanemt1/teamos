# TeamOS

TeamOS is a project management app: a Vue 3 client and a Supabase backend (Postgres, Auth, and Realtime). People sign in, work inside a team, and manage projects on a four-column kanban board. The client talks to Supabase directly. This repository has no application server.

**Live demo:** [teamos-2xqxg230i-aymanemt1.vercel.app](https://teamos-2xqxg230i-aymanemt1.vercel.app)

## Features

What the client actually implements:

- **Auth.** Email and password sign-in (`/login`) and sign-up (`/register`). Routes that need a session redirect to login; a signed-in user who opens a guest page is sent to the dashboard. A `handle_new_user` trigger inserts a `profiles` row on signup. The display name stored there is the capitalized part of the email before `@`. The sign-up form also sends a name in user metadata; the trigger does not read it. `seed.sql` later sets the demo profile names.
- **App shell.** Desktop sidebar from 900px up, a compact top bar and horizontal nav below that, a team switcher when the user belongs to more than one team, and sign out. Toasts report success and failure.
- **Dashboard (`/`).** Greeting, four stat cards (active projects, tasks with status `done`, member count, and subtask completion percent), an SVG donut of tasks by status, a seven-day bar chart of tasks whose `completed_at` falls on that day, and the latest 15 activity rows. Switching teams reloads the page.
- **Board (`/board`).** One active project at a time. Columns are Backlog, In Progress, Review, and Done. Cards show priority, project key, due date, tags, subtask progress, and assignee. HTML drag-and-drop reorders cards and writes `status` and `position`. A status change is logged as `task.moved`; a drop onto Done is also logged as `task.completed`. `completed_at` is set when status changes to Done in the task drawer, not by the drag handler.
- **Tasks.** A create modal (title, description, project, column, priority, due date, assignee, comma-separated tags) and a slide-over drawer to edit those fields, add/toggle/delete subtasks, post comments, and delete the task. The board subscribes to Postgres changes on `tasks` (for the open project), `subtasks`, and `comments`, then refetches. The comment UI posts new comments; it does not edit or delete them.
- **Projects (`/projects`).** Grid of the current team's projects with key, color, description, active/archived badge, and a done-task progress bar. Create and edit (name, key, description, color). Archive and restore. Delete asks for confirmation and removes the project and its tasks. Archived projects stay on this page and are omitted from the board's project list.
- **Team (`/team`).** Roster with avatar, name, email, and role (`owner`, `admin`, or `member`). Owners and admins can add someone who already has an account by email, change another member's role, and remove them. The client has no action that creates a team.
- **Activity log.** The client inserts a row after project created, task created, task updated, task moved, task completed (via drag onto Done), task commented, and member added. The dashboard reads that feed. It does not subscribe to it live.

## Tech stack

| Piece | What the repo uses |
| --- | --- |
| UI | Vue 3.4, Vue Router 4.4, Pinia 2.2 |
| Build | Vite 5.4 (`client/vite.config.js` serves dev on port 5173) |
| Styling | Tailwind CSS 3.4, PostCSS, Autoprefixer, Inter |
| Language | JavaScript (`.vue` and `.js`). No TypeScript in this repo |
| Backend | Supabase: Postgres, email/password Auth, Row Level Security, Realtime |
| Client SDK | `@supabase/supabase-js` `^2.45.4` (lockfile resolves 2.117.3) |

The locked Supabase client declares Node `>=22`. Vite 5 accepts Node 18 or 20 and newer. Use Node 22 or newer so both are satisfied.

## Project structure

```
.
├── README.md
├── client/                      Vue 3 app
│   ├── .env.example             VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   └── src/
│       ├── main.js              createApp, Pinia, router
│       ├── App.vue              sidebar, mobile nav, sign out
│       ├── router/index.js      routes and auth guard
│       ├── stores/              auth, team, projects, tasks
│       ├── views/               Login, Register, Dashboard, Board, Projects, Team
│       ├── components/          cards, drawer, modals, charts, toasts
│       └── lib/                 supabase client, activity log, statuses, time
└── supabase/
    ├── README.md                backend run order and RLS notes
    ├── schema.sql               tables, triggers, RLS, Realtime publication
    └── seed.sql                 demo team, projects, tasks, subtasks, comments, activity
```

## Setup

### 1. Create a Supabase project

In the [Supabase dashboard](https://supabase.com), create a project. From **Settings → API**, copy the project URL and the anon public key. Keep the service role key on the server side of Supabase only. The client never uses it.

### 2. Apply the schema

In the dashboard **SQL Editor** (it runs as the project owner, which the `auth.users` trigger needs), paste and run `supabase/schema.sql`.

That file is meant to be re-run. The drop section at the top removes the public tables, helper functions, and the signup trigger, then recreates them. Running it again wipes application data in those tables.

It creates eight tables: `profiles`, `teams`, `team_members`, `projects`, `tasks`, `subtasks`, `comments`, `activities`. It also adds indexes, `updated_at` triggers, Row Level Security policies, grants for `authenticated`, and adds `tasks`, `comments`, and `activities` to the `supabase_realtime` publication.

### 3. Create the demo users

In **Authentication → Users → Add user**, create both accounts and enable **Auto Confirm User**:

- `owner@teamos.test`
- `member@teamos.test`

Choose the password for each user there. `seed.sql` does not set passwords. Creating the user fires `handle_new_user`, which inserts the profile.

### 4. Load demo data

Paste and run `supabase/seed.sql` after both users exist. If either email is missing, the script stops and raises a notice. It does not insert auth users.

The seed inserts:

| Data | Contents |
| --- | --- |
| Team | Acme Inc (`acme-inc`). Owner is Ava Owner; member is Ben Member |
| Projects | Website Redesign (`WEB`), Mobile App (`MOB`), Marketing Site (`MKT`), all active |
| Work | 14 tasks across backlog, in progress, review, and done; 9 subtasks; 4 comments; 8 activity rows |

More detail is in `supabase/README.md`.

### 5. Configure and run the client

```bash
cd client
cp .env.example .env
npm install
npm run dev
```

Set these in `client/.env` (names only; values come from the Supabase API settings):

| Variable | Role |
| --- | --- |
| `VITE_SUPABASE_URL` | Project URL |
| `VITE_SUPABASE_ANON_KEY` | Anon public key |

Restart `npm run dev` after changing `.env`. If either variable is missing, the login and register pages say Supabase is not configured and the sign-in button stays disabled.

The dev server listens on port **5173**. Sign in with one of the demo emails and the password you set in the dashboard.

## Scripts

All scripts live in `client/package.json`. There is no test or lint script.

| Command | What it does |
| --- | --- |
| `npm run dev` | Vite dev server on port 5173 |
| `npm run build` | Production build into `client/dist/` |
| `npm run preview` | Serve the production build locally |

## Routes

| Path | Auth | Screen |
| --- | --- | --- |
| `/login` | Guest only | Sign in |
| `/register` | Guest only | Create an account |
| `/` | Required | Dashboard |
| `/board` | Required | Kanban board |
| `/projects` | Required | Project grid |
| `/team` | Required | Members and roles |
| anything else | — | Redirects to `/` |

## Security notes

- Row Level Security is on for every application table. A signed-in user can read teams they belong to. Project, task, subtask, comment, and activity access is scoped to that membership.
- Profiles: a user can read their own row, and other profiles only when they share a team. They can update only their own profile. Clients cannot insert or delete profiles; the signup trigger creates the row.
- Comments: team members can read, insert, and update. Only the author can delete. The drawer UI only inserts.
- Activities: members can read and insert. There is no client update or delete policy.
- **Teams cannot be created from the app.** The `teams` insert policy requires `is_team_member(id)` on the new row, so a user who is not already a member cannot insert one. Create the team in the SQL editor (or with the service role), then insert the creator into `team_members`. That is what `seed.sql` does. Owners and admins can update or delete an existing team at the database level; the Vue UI does not expose those actions.
- Adding a member looks up `profiles.email`. The person must already have signed up. New members are inserted with role `member`.
