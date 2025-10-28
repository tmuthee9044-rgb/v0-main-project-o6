#!/bin/bash

# Fix NPM dependency resolution issues
# This script cleans all npm caches and reinstalls dependencies

set -e

echo "🧹 Cleaning npm cache and lock files..."

# Remove all cached files
rm -rf node_modules
rm -f package-lock.json
rm -rf .next

# Clear npm cache
npm cache clean --force

echo "📦 Installing dependencies with --legacy-peer-deps..."

# Install with legacy peer deps to handle React version conflicts
npm install --legacy-peer-deps

echo "✅ Dependencies installed successfully!"
echo ""
echo "You can now run: npm run dev"
