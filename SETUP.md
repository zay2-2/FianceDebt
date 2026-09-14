# Debt Tracker — setup

The app is a single `index.html` backed by [Supabase](https://supabase.com)
(hosted PostgreSQL + authentication). There is nothing to install: no database
to download, no build step, no server to run.

---

## 1. Create the Supabase project

1. Sign up at **supabase.com** and create a new project.
2. Pick a region close to you.
3. Save the database password it generates — you won't need it for this app,
   but it's the only time it's shown.

Wait for the project to finish provisioning (a minute or two).

## 2. Create the tables

1. In your project, open **SQL Editor → New query**.
2. Paste the entire contents of [`schema.sql`](schema.sql).
3. Click **Run**.

This creates one table, `trackers`, plus the security policies and triggers.
It's safe to run more than once.

To confirm it worked: **Table Editor** should now list a `trackers` table, and
**Authentication → Policies** should show four policies on it.

## 3. Connect the app

1. Go to **Project Settings → API**.
2. Copy the **Project URL** and the **anon / public** key.
3. Open `index.html`, find the config block near the top of the `<script>`, and
   paste them in:

```js
const SUPABASE_URL      = 'https://yourproject.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOi...';
```

Reload the page and you'll get a sign-in screen instead of the "not connected"
notice.

> **On the anon key:** it is designed to be public and ships in the client of
> every Supabase web app. It grants no access by itself — the row-level
> security policies in `schema.sql` decide which rows any request may touch.
>
> **Never** put the `service_role` key in this file. That key bypasses RLS
> entirely and must stay server-side.

## 4. Email confirmation (optional but recommended)

By default Supabase emails a confirmation link on sign-up. While testing you
can turn this off under **Authentication → Providers → Email** so accounts work
immediately.

Supabase's built-in email sender is rate-limited and only intended for
development. Before other people use this, connect a real SMTP provider under
**Authentication → Emails**.

---

## Running it

Because auth uses redirects and browser storage, open the app over `http://`
rather than double-clicking the file. Any static server works:

```bash
python3 -m http.server 4173
```

Then visit `http://localhost:4173`.

## Deploying

It's a static site, so anything free will host it — Netlify, Vercel, Cloudflare
Pages, or GitHub Pages. Drag the folder in, or point the host at this repo.

Afterwards, add your live URL to Supabase under
**Authentication → URL Configuration → Redirect URLs**, so password-reset and
confirmation links come back to the right place.

---

## How your data is protected

Every row in `trackers` is stamped with a `user_id`. The RLS policies compare
that column to `auth.uid()` — the account making the request — on every read
and every write. Postgres enforces this itself, so even a bug in the frontend
cannot return someone else's tracker.

Locally, the browser cache is namespaced per account
(`debtTracker_v1_<user-id>`). Two people using the same browser get separate
caches.

## Known gaps

- **Alpha Vantage key** is stored in your tracker document and used from the
  browser. That's fine for your own free key; if this ever has real users,
  proxy those calls through a Supabase Edge Function instead.
- **Conflict handling is last-write-wins.** Editing the same account in two
  tabs at once, offline, can lose the older edit. The `updated_at` column is
  already there to build on if this becomes a problem.
- **No account deletion in the UI** yet. The `on delete cascade` is in place,
  so deleting the auth user removes their tracker.
