# Database Migration System

This directory contains SQL migration scripts that work with both **offline PostgreSQL** and **Neon serverless** databases.

## Migration Naming Convention

Migrations are numbered sequentially:
- `001_initial_schema.sql` - Initial database schema
- `002_add_feature_x.sql` - Add feature X tables/columns
- `003_update_feature_y.sql` - Update feature Y

## How Migrations Work

### During Installation
The `install.sh` script automatically runs all migrations in order when setting up the database.

### Via Settings Page
The `/settings` page has a "Sync Database Schema" button that:
1. Checks database connection (works for both Neon and PostgreSQL)
2. Runs all pending migrations
3. Reports success/errors

### Manual Execution
You can also run migrations manually:

\`\`\`bash
# For offline PostgreSQL
psql -U isp_admin -d isp_system -f scripts/001_initial_schema.sql

# For Neon (using psql with connection string)
psql "postgresql://user:pass@host/db" -f scripts/001_initial_schema.sql
\`\`\`

## Creating New Migrations

When adding new features that require database changes:

1. **Create a new migration file** with the next number:
   \`\`\`bash
   touch scripts/002_add_loyalty_program.sql
   \`\`\`

2. **Write SQL that works on both databases**:
   \`\`\`sql
   -- Migration 002: Add Loyalty Program
   -- Compatible with PostgreSQL and Neon
   
   CREATE TABLE IF NOT EXISTS loyalty_points (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       customer_id UUID REFERENCES customers(id),
       points INTEGER DEFAULT 0,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   
   -- Record migration
   INSERT INTO schema_migrations (migration_name) 
   VALUES ('002_add_loyalty_program') 
   ON CONFLICT (migration_name) DO NOTHING;
   \`\`\`

3. **Test on both databases**:
   - Test locally with PostgreSQL
   - Test on Neon if using cloud database

4. **Update the sync endpoint** if needed (usually automatic)

## Compatibility Guidelines

To ensure migrations work on both PostgreSQL and Neon:

### ✅ DO:
- Use `CREATE TABLE IF NOT EXISTS`
- Use `CREATE INDEX IF NOT EXISTS`
- Use `UUID` with `gen_random_uuid()`
- Use standard PostgreSQL data types
- Use `ON CONFLICT DO NOTHING` for idempotent inserts
- Add migration tracking at the end

### ❌ DON'T:
- Use PostgreSQL-specific extensions without checking availability
- Use `SERIAL` (use `UUID` instead for better distribution)
- Hardcode connection strings or credentials
- Use database-specific syntax

## Migration Tracking

The `schema_migrations` table tracks which migrations have been applied:

\`\`\`sql
SELECT * FROM schema_migrations ORDER BY applied_at;
\`\`\`

This prevents running the same migration twice.

## Rollback

Currently, migrations don't have automatic rollback. If you need to undo a migration:

1. Create a new migration that reverses the changes
2. Name it appropriately (e.g., `003_rollback_feature_x.sql`)

## Future Updates

When the system is updated with new features:

1. New migration files will be added to this directory
2. Run `./install.sh --fix-db` to apply new migrations
3. Or use the "Sync Database Schema" button in `/settings`

Both methods work for offline PostgreSQL and Neon databases.
