# FianceDebt

A simple debt tracker to help you figure out when you'll be debt-free.

**Use it here: https://zay2-2.github.io/FianceDebt/**

Create an account, add your debts, income, and expenses, and it shows you the payoff timeline and breaks it into phases so the goal feels reachable. Your data syncs to your account on every device.

## What it does

- Track your debts (balance, APR, minimum payment)
- Log your income and monthly expenses
- See your payoff date and whether you're on track
- View a month-by-month breakdown for each debt
- **Plan two ways:** set a target date and see the payment it takes, or set a monthly budget and see when you'll be debt-free
- **Avalanche or snowball:** compare paying highest-APR first against smallest-balance first, with the interest and time each one saves
- **Accounts:** sign in and your tracker syncs across devices
- Track stocks and export or import a backup of your data

## How your data is protected

Every account's tracker is a single row in a Postgres database, stamped with the account's user id. Row-level security policies compare that id to the signed-in user on every read and write, so the database itself refuses to return anyone else's data. See [`schema.sql`](schema.sql) for the exact policies.

The public API key in `index.html` is designed to ship in the browser and grants no access on its own.

## Running your own copy

Want to self-host with your own database? Full steps are in [SETUP.md](SETUP.md); the short version:

1. Create a free [Supabase](https://supabase.com) project and run [`schema.sql`](schema.sql) in its SQL Editor.
2. Paste your project URL and publishable key into the config block at the top of the script in `index.html`.
3. Serve the folder and open it in your browser:

```bash
git clone https://github.com/zay2-2/FianceDebt.git
cd FianceDebt
python3 -m http.server 4173
```

Then visit `http://localhost:4173`.

Without Supabase keys, the app offers a preview mode that saves to your browser only.

## Built with

Plain HTML, CSS, and JavaScript with no build step. Accounts and storage run on Supabase (PostgreSQL), loaded from a CDN. Hosted on GitHub Pages.
