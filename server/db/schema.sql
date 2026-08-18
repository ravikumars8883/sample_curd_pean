-- ---------------------------------------------------------------------------
-- sample_curd_pean : PostgreSQL schema
-- Applied by `npm run migrate` (server/db/migrate.js) or manually with:
--   psql "$DATABASE_URL" -f server/db/schema.sql
-- The whole file is idempotent, so it is safe to run more than once.
-- ---------------------------------------------------------------------------

BEGIN;

-- Main CRUD entity used by the Express API and the Angular client.
CREATE TABLE IF NOT EXISTS products (
    id          SERIAL          PRIMARY KEY,
    name        VARCHAR(150)    NOT NULL,
    description TEXT,
    price       NUMERIC(10, 2)  NOT NULL DEFAULT 0 CHECK (price >= 0),
    quantity    INTEGER         NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    available   BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Case-insensitive lookups / search by name (used by GET /api/products?search=).
CREATE INDEX IF NOT EXISTS idx_products_name_lower ON products (LOWER(name));

-- Default list ordering is newest first.
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products (created_at DESC);

-- Keep updated_at accurate without trusting the application layer.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_products_set_updated_at ON products;

CREATE TRIGGER trg_products_set_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Seed data, only when the table is still empty.
INSERT INTO products (name, description, price, quantity, available)
SELECT * FROM (VALUES
    ('Mechanical Keyboard', 'Tenkeyless board with hot-swappable switches', 89.99, 25, TRUE),
    ('27 inch 4K Monitor',  'IPS panel, USB-C power delivery',              329.00, 12, TRUE),
    ('USB-C Dock',          'Dual display, 100W passthrough, 2.5GbE',       149.50,  0, FALSE)
) AS seed (name, description, price, quantity, available)
WHERE NOT EXISTS (SELECT 1 FROM products);

COMMIT;
