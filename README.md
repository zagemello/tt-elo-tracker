# TT Elo Tracker

A table tennis ELO tracker for small groups. Tracks match history, player ratings (Glicko-inspired), win streaks, and head-to-head records.

**Live app:** https://tt-elo-tracker.vercel.app

## Local setup

```sh
git clone https://github.com/zagemello/tt-elo-tracker.git
cd tt-elo-tracker
npm install
```

Create a `.env.local` file in the root — ask Anthony for the credentials:

```
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
```

```sh
npm run dev
```

That's it. Everyone shares the same Supabase database — no separate DB setup needed.

## Contributing

1. Ask Anthony to add you as a collaborator on GitHub (Settings → Collaborators)
2. Get the `.env.local` credentials from Anthony
3. Create a branch, make your changes, open a pull request

## Fresh Supabase setup (only needed if starting from scratch)

Run `supabase/schema.sql` once in the Supabase SQL Editor, then:
1. In Supabase Auth settings, disable **Confirm email**
2. Sign up in the app with your username
3. Grant yourself admin: `UPDATE public.profiles SET is_admin = true WHERE display_name = 'YourUsername';`

## Tech stack

- Vue 3 + Vite + Pinia
- Supabase (Postgres + Auth + RLS)
- Vercel (auto-deploys from `main`)
