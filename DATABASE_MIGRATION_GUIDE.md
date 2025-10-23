# Database Import Migration Guide

## Overview

This guide explains how to migrate the ISP Management System from using `@neondatabase/serverless` directly to using the smart `db-client` wrapper that supports both local PostgreSQL and Neon cloud databases.

## Problem

The application was originally built to use Neon's serverless database driver, which only works with Neon cloud databases via HTTPS. This causes errors when trying to use a local PostgreSQL database:

\`\`\`
Error: connect ECONNREFUSED 127.0.0.1:443
\`\`\`

## Solution

We've created a smart database client wrapper (`lib/db-client.ts`) that:
- Automatically detects if you're using Neon cloud or local PostgreSQL
- Uses the appropriate driver for each database type
- Provides a unified `sql` interface for all database operations

## Migration Steps

### Automatic Migration (Recommended)

Run the automated migration script to update all 346+ files:

\`\`\`bash
# Make the script executable
chmod +x migrate-db-imports.sh

# Run the migration
./migrate-db-imports.sh
\`\`\`

This script will:
1. Find all files importing from `@neondatabase/serverless`
2. Replace imports with `import { sql } from "@/lib/db-client"`
3. Remove redundant `const sql = neon(...)` lines
4. Show a summary of changes

### Manual Migration (For Individual Files)

If you prefer to migrate files manually or need to update a specific file:

**Before:**
\`\`\`typescript
import { neon } from "@neondatabase/serverless"

const sql = neon(process.env.DATABASE_URL!)

export async function getData() {
  const result = await sql`SELECT * FROM customers`
  return result
}
\`\`\`

**After:**
\`\`\`typescript
import { sql } from "@/lib/db-client"

export async function getData() {
  const result = await sql`SELECT * FROM customers`
  return result
}
\`\`\`

### Verification

After migration, verify the changes:

\`\`\`bash
# Check what was changed
git diff

# Test the application
npm run dev

# Try saving company settings or other database operations
# Should work with both local PostgreSQL and Neon cloud
\`\`\`

## How It Works

The `lib/db-client.ts` wrapper:

\`\`\`typescript
// Detects database type from connection string
const isNeonDatabase = connectionString.includes("neon.tech")

// Uses appropriate driver
export const sql = isNeonDatabase
  ? neon(connectionString)           // For Neon cloud
  : postgres(connectionString, {     // For local PostgreSQL
      max: 10,
      idle_timeout: 20,
      connect_timeout: 10,
    })
\`\`\`

## Environment Variables

### For Local PostgreSQL:
\`\`\`env
DATABASE_URL="postgresql://isp_admin:isp_secure_password@localhost:5432/isp_system"
\`\`\`

### For Neon Cloud:
\`\`\`env
DATABASE_URL="postgres://user:pass@ep-xxx.neon.tech/dbname?sslmode=require"
\`\`\`

The system automatically detects which one you're using!

## Troubleshooting

### Error: "Cannot find module '@/lib/db-client'"

Make sure your `tsconfig.json` has the path alias configured:

\`\`\`json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./*"]
    }
  }
}
\`\`\`

### Error: "Module 'postgres' not found"

Install the postgres package:

\`\`\`bash
npm install postgres
\`\`\`

### Still getting ECONNREFUSED errors

1. Check your `.env.local` file has the correct DATABASE_URL
2. Verify PostgreSQL is running: `sudo systemctl status postgresql`
3. Test connection: `psql -U isp_admin -d isp_system -h localhost`

## Files Updated

The migration updates approximately 346 files across:
- `app/actions/*.ts` - Server actions
- `app/api/**/*.ts` - API routes
- `lib/*.ts` - Utility functions

## Rollback

If you need to rollback the changes:

\`\`\`bash
git checkout -- .
\`\`\`

Or restore specific files:

\`\`\`bash
git checkout -- app/actions/company-settings-actions.ts
