#!/bin/bash

# ISP Management System - Neon Database Installation Script
# This script uses your existing Neon database (no local PostgreSQL needed)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

echo "========================================="
echo "ISP Management System - Quick Install"
echo "Using Neon Cloud Database"
echo "========================================="

# Step 1: Check Node.js
print_info "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_success "Node.js installed"
else
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        print_error "Node.js version is too old. Upgrading to Node.js 20..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    print_success "Node.js $(node -v) is installed"
fi

# Step 2: Verify environment variables
print_info "Checking database connection..."
if [ -z "$DATABASE_URL" ]; then
    print_error "DATABASE_URL not found in environment"
    print_info "Your Neon database URL should be set in .env.local"
    exit 1
fi
print_success "Database connection configured"

# Step 3: Install dependencies
print_info "Installing npm dependencies..."
npm install --legacy-peer-deps
print_success "Dependencies installed"

# Step 4: Fix missing database schema
print_info "Checking database schema..."
print_info "Visit http://localhost:3000/api/fix-database-schema after starting the app to add missing tables"

# Step 5: Build the application
print_info "Building application..."
npm run build
print_success "Application built successfully"

echo ""
echo "========================================="
print_success "Installation Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Start the application:"
echo "   npm run dev"
echo ""
echo "2. Fix missing database tables (if needed):"
echo "   curl -X POST http://localhost:3000/api/fix-database-schema"
echo ""
echo "3. Access the application:"
echo "   http://localhost:3000"
echo ""
echo "========================================="
