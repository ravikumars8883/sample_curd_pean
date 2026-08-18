# sample_curd_pean — Setup and Run Guide

A minimal **CRUD** sample on the **PEAN** stack — **P**ostgreSQL, **E**xpress, **A**ngular, **N**ode.js.
One resource (`products`) is wired end to end: an Express/Node REST API talking to PostgreSQL through
parameterised `pg` queries, and an Angular client that lists, creates, edits and deletes rows.

---

## Repository layout

```
sample_curd_pean/
├── README.md                # project blurb
├── docs/
│   └── README.md            # this guide
├── server/                  # Node.js + Express REST API
│   ├── package.json
│   ├── .env.example         # copy to server/.env and edit
│   ├── db/
│   │   ├── index.js         # pg Pool / connection setup
│   │   └── schema.sql       # products table DDL + seed rows
│   ├── scripts/
│   │   └── migrate.js       # applies db/schema.sql to the database
│   ├── routes/              # /api/products CRUD routes
│   └── server.js            # app entry point
└── client/                  # Angular single-page frontend
    ├── package.json
    └── src/app/
        ├── product.model.ts     # Product interface (API shape)
        ├── product.service.ts   # HttpClient CRUD calls
        └── products/            # list + form components
```

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Node.js | 18 LTS or newer | ships with `npm`; required by the current Angular CLI |
| npm | 9 or newer | comes with Node.js |
| PostgreSQL | 13 or newer | local install, Docker container, or a hosted instance |
| Angular CLI | as pinned in `client/package.json` | optional — `npx ng` works without a global install |

Check what you have:

```bash
node -v && npm -v && psql --version
```

---

## 1. Get the code

```bash
git clone https://github.com/ravikumars8883/sample_curd_pean.git
cd sample_curd_pean
```

## 2. Create the database

Create an empty database — the schema is applied in the next step.

```bash
createdb sample_curd_pean
# or, from inside psql:
psql -U postgres -c "CREATE DATABASE sample_curd_pean;"
```

Prefer Docker? This gives you a throwaway server on port 5432:

```bash
docker run --name pean-pg -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=sample_curd_pean -p 5432:5432 -d postgres:16
```

## 3. Configure and start the backend

```bash
cd server
npm install
cp .env.example .env      # Windows: copy .env.example .env
```

Edit `server/.env` so it points at your database:

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `3000` | port the Express API listens on |
| `DATABASE_URL` | — | full connection string, e.g. `postgres://postgres:postgres@localhost:5432/sample_curd_pean` |
| `PGHOST` / `PGPORT` | `localhost` / `5432` | used when `DATABASE_URL` is not set |
| `PGUSER` / `PGPASSWORD` | `postgres` / — | database credentials |
| `PGDATABASE` | `sample_curd_pean` | database name |

`DATABASE_URL` takes precedence when present; otherwise the individual `PG*` values are used. Never
commit `.env` — only `.env.example` belongs in Git.

Create the table and seed rows, then run the API:

```bash
npm run migrate     # applies server/db/schema.sql
npm run dev         # watch mode → http://localhost:3000
# or
npm start           # plain node
```

Smoke-test it:

```bash
curl http://localhost:3000/api/products
```

## 4. Start the Angular frontend

In a **second terminal**:

```bash
cd client
npm install
npm start           # ng serve → http://localhost:4200
```

The dev server proxies `/api` to `http://localhost:3000`, so the browser sees a single origin and
there is no CORS configuration to do in development. Open <http://localhost:4200> and the product
list should render from PostgreSQL.

---

## API reference

Base URL: `http://localhost:3000/api`

| Method | Path | Body | Result |
|---|---|---|---|
| `GET` | `/products` | — | `200` — array of products |
| `GET` | `/products/:id` | — | `200` — one product, `404` if unknown |
| `POST` | `/products` | `{ "name", "description", "price", "quantity" }` | `201` — the created product |
| `PUT` | `/products/:id` | same fields as `POST` | `200` — the updated product |
| `DELETE` | `/products/:id` | — | `204` — no content |

Every handler uses parameterised queries (`$1`, `$2`, …), which is what stops user input from being
interpreted as SQL.

---

## Production build

```bash
cd client && npm run build      # emits dist/ (static assets)
cd ../server && npm start       # serve the API; host dist/ behind it or on a CDN
```

Set `NODE_ENV=production` and supply `DATABASE_URL` from your platform's secret store rather than a
`.env` file on disk.

---

## Troubleshooting

- **`ECONNREFUSED 127.0.0.1:5432`** — PostgreSQL is not running, or listens on a different port than
  the one in `.env`.
- **`password authentication failed`** — `PGUSER`/`PGPASSWORD` (or the credentials inside
  `DATABASE_URL`) don't match the server; special characters in a URL must be percent-encoded.
- **`relation "products" does not exist`** — `npm run migrate` hasn't been run against this database.
- **`EADDRINUSE :3000` / `:4200`** — another process holds the port; change `PORT` in `.env`, or run
  `ng serve --port 4300`.
- **Empty list although the API returns rows** — check the browser console and confirm the client's
  `/api` proxy target matches the port the server actually started on.

---

## License

Sample code, provided as-is for learning and demonstration purposes.
