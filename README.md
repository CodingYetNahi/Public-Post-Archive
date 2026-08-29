# Public Post Archive

Public Post Archive is a React and TypeScript web application built with Vite. It uses hash-based routing so direct navigation works when the site is hosted below the `/Public-Post-Archive/` GitHub Pages path.

The platform provides database-backed browsing, post records, topics, comparisons, timelines, claim exploration, analytics, corrections, and an administrator-only workspace. Public navigation never exposes an administration link.

## Requirements

- Node.js 20.19 or later
- npm
- A Supabase project URL and publishable key when connecting the application to Supabase

Never expose a Supabase service-role key in this frontend. The publishable key is intended for the client bundle, and access must be protected with appropriate Row Level Security policies.

## Local setup

1. Install dependencies:

   ```sh
   npm install
   ```

2. Copy the environment template:

   ```sh
   cp .env.example .env.local
   ```

3. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` in `.env.local`.

4. Start the development server:

   ```sh
   npm run dev
   ```

## Quality checks

```sh
npm run typecheck
npm run lint
npm run build
```

## Database migration

The additive migration at `supabase/migrations/202608280001_research_archive.sql` retains the existing `archive_accounts` and `archive_posts` tables and records. It adds research metadata, supporting tables, duplicate constraints, indexes, full-text search, administrator checks, and least-privilege RLS policies.

Apply it once from the repository root with a Supabase CLI session linked to the existing project:

```sh
supabase db push
```

Then add administrator UUIDs to `archive_admins` through the Supabase SQL editor using a trusted database-owner session. Never place elevated keys in this repository or browser environment.

## Routes

Public hash routes: `/`, `/browse`, `/post/:id`, `/topics`, `/topics/:topic`, `/compare`, `/timeline`, `/claims`, `/analytics`, `/about`, `/methodology`, and `/corrections`.

Protected hash routes: `/admin`, `/admin/posts/new`, `/admin/import`, `/admin/review`, `/admin/categories`, `/admin/rules`, `/admin/accounts`, `/admin/import-history`, and `/admin/settings`.

## GitHub Pages deployment

The workflow at `.github/workflows/deploy-pages.yml` builds and deploys the application on every push to `main`, and it can also be started manually from the Actions tab.

Before the first deployment:

1. In the repository settings, select **GitHub Actions** as the Pages source.
2. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` as GitHub Actions repository secrets.
3. Push to `main` or run the **Deploy Public Post Archive** workflow manually.

Vite emits production assets for `/Public-Post-Archive/`, and the deployed site is available at:

<https://codingyetnahi.github.io/Public-Post-Archive/>

The workflow deliberately does not accept or expose a Supabase service-role key.
