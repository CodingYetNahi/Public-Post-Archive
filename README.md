# Public Post Archive

Public Post Archive is a React and TypeScript web application built with Vite. It uses hash-based routing so direct navigation works when the site is hosted below the `/Public-Post-Archive/` GitHub Pages path.

## Requirements

- Node.js 20.19 or later
- npm
- A Supabase project URL and anonymous client key when connecting the application to Supabase

Never expose a Supabase service-role key in this frontend. The anonymous key is the only Supabase key intended for the client bundle, and access must be protected with appropriate Row Level Security policies.

## Local setup

1. Install dependencies:

   ```sh
   npm install
   ```

2. Copy the environment template:

   ```sh
   cp .env.example .env.local
   ```

3. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `.env.local`.

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

## GitHub Pages deployment

The workflow at `.github/workflows/deploy-pages.yml` builds and deploys the application on every push to `main`, and it can also be started manually from the Actions tab.

Before the first deployment:

1. In the repository settings, select **GitHub Actions** as the Pages source.
2. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` as GitHub Actions repository secrets.
3. Push to `main` or run the **Deploy Public Post Archive** workflow manually.

Vite emits production assets for `/Public-Post-Archive/`, and the deployed site is available at:

<https://codingyetnahi.github.io/Public-Post-Archive/>

The workflow deliberately does not accept or expose a Supabase service-role key.
