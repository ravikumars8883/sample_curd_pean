'use strict';

/**
 * Applies server/db/schema.sql to the configured database.
 * Run with:  npm run migrate     (from the server/ folder)
 *
 * schema.sql is idempotent (CREATE TABLE IF NOT EXISTS, CREATE OR REPLACE,
 * conditional seed), so re-running it is harmless.
 */

const fs = require('fs');
const path = require('path');
const db = require('./index');

async function migrate() {
  const schemaPath = path.join(__dirname, 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');

  const info = await db.healthCheck();
  console.log('[migrate] connected to "%s" at %s', info.database, info.now);

  await db.query(sql);
  console.log('[migrate] schema applied from %s', path.relative(process.cwd(), schemaPath));

  const { rows } = await db.query('SELECT COUNT(*)::int AS count FROM products');
  console.log('[migrate] products table ready, %d row(s) present', rows[0].count);
}

migrate()
  .then(() => db.close())
  .then(() => process.exit(0))
  .catch(async (err) => {
    console.error('[migrate] failed:', err.message);
    await db.close().catch(() => {});
    process.exit(1);
  });
