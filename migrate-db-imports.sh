#!/bin/bash

# Migration script to update all database imports
# This script updates all files to use the smart db-client wrapper

set -e

echo "🔄 Starting database import migration..."
echo ""

# Check if we're in the project root
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Make the Node.js script executable
chmod +x scripts/migrate-database-imports.js

# Run the migration
echo "📝 Running migration script..."
node scripts/migrate-database-imports.js

echo ""
echo "✅ Migration complete!"
echo ""
echo "📋 Summary of changes:"
git diff --stat || echo "No git repository found"

echo ""
echo "🧪 Testing the changes..."
echo "Run: npm run dev"
echo ""
echo "If everything works, commit the changes:"
echo "git add ."
echo "git commit -m 'Migrate to smart database client for local PostgreSQL support'"
