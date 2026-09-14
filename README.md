# FianceDebt

A simple debt tracker to help you figure out when you'll be debt-free.

Add your debts, income, and expenses — it shows you the payoff timeline and breaks it into phases so the goal feels reachable.

## What it does

- Track your debts (balance, APR, minimum payment)
- Log your income and monthly expenses
- See your payoff date and whether you're on track
- View a month-by-month breakdown for each debt
- **Plan two ways:** set a target date and see the payment it takes, or set a monthly budget and see when you'll be debt-free
- **Avalanche or snowball:** compare paying highest-APR first against smallest-balance first, with the interest and time each one saves
- **Accounts:** sign in and your tracker syncs across devices
- Track stocks and export or import a backup of your data

## How to use it

The app needs a free [Supabase](https://supabase.com) project for accounts. Full steps are in [SETUP.md](SETUP.md); the short version:

1. Create a Supabase project and run [`schema.sql`](schema.sql) in its SQL Editor.
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

Plain HTML, CSS, and JavaScript with no build step. Accounts and storage run on Supabase (PostgreSQL), loaded from a CDN.
