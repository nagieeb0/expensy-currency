 Expensy – Expense Tracker

Expensy is a simple **expense tracker** built with Phoenix **LiveView** and PostgreSQL :

- **LiveView + Ecto**: classic Phoenix approach with contexts and schemas.


---

 🚀 Features
- Categories with `name`, `description`, and `monthly_budget`.
- Expenses with `description`, `amount (decimal)`, `date`, and optional `notes`.
- Real-time updates with Phoenix LiveView.
- Totals, remaining budget, and progress bar for each category.
- Validations and DB constraints to prevent invalid data.
- Proper **Decimal** usage for all money calculations (no floats).
- Seeds for quick demo data.

---

 🛠️ Getting Started

 Prerequisites
- Elixir & Erlang
- PostgreSQL
- Node & npm (for assets)

 Setup
```bash
 Install deps & setup DB
mix setup

 Run migrations
mix ecto.migrate

 Seed data
mix run priv/repo/seeds.exs

 Start server
mix phx.server
 Visit http://localhost:4000
