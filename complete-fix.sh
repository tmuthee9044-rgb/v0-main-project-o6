#!/bin/bash

# ISP System - Complete Fix Script
# This script fixes Node.js, database, and directory issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  ISP SYSTEM - COMPLETE FIX SCRIPT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Fix directory structure
echo -e "${BLUE}━━━ Step 1: Fixing Directory Structure ━━━${NC}"
CURRENT_DIR=$(pwd)
echo "Current directory: $CURRENT_DIR"

# Find the correct project root (where package.json is)
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}⚠ Not in project root. Searching for package.json...${NC}"
    
    # Search up to 10 levels
    for i in {1..10}; do
        if [ -f "../package.json" ]; then
            cd ..
            echo -e "${GREEN}✓ Found project root: $(pwd)${NC}"
            break
        fi
        cd ..
    done
    
    if [ ! -f "package.json" ]; then
        echo -e "${RED}✗ Could not find package.json. Please navigate to the project root manually.${NC}"
        exit 1
    fi
fi

PROJECT_ROOT=$(pwd)
echo -e "${GREEN}✓ Project root: $PROJECT_ROOT${NC}"
echo ""

# Step 2: Fix Node.js version
echo -e "${BLUE}━━━ Step 2: Fixing Node.js Version ━━━${NC}"
NODE_VERSION=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)

if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${YELLOW}⚠ Node.js version too old (v$NODE_VERSION). Upgrading to v20...${NC}"
    
    # Method 1: Try using snap (fastest)
    if command -v snap &> /dev/null; then
        echo "▶ Installing Node.js 20 via snap..."
        if sudo snap install node --classic --channel=20; then
            export PATH="/snap/bin:$PATH"
            echo 'export PATH="/snap/bin:$PATH"' >> ~/.bashrc
            echo -e "${GREEN}✓ Node.js 20 installed via snap${NC}"
            
            # Verify
            NEW_VERSION=$(node -v)
            echo "New Node.js version: $NEW_VERSION"
        else
            echo -e "${YELLOW}⚠ Snap installation failed, trying alternative method...${NC}"
        fi
    fi
    
    # Method 2: Try using nvm
    NODE_VERSION=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo "▶ Installing Node.js 20 via nvm..."
        
        # Install nvm if not present
        if [ ! -d "$HOME/.nvm" ]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        fi
        
        # Load nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Install Node.js 20
        nvm install 20
        nvm use 20
        nvm alias default 20
        
        echo -e "${GREEN}✓ Node.js 20 installed via nvm${NC}"
        NEW_VERSION=$(node -v)
        echo "New Node.js version: $NEW_VERSION"
    fi
    
    # Verify final version
    NODE_VERSION=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "${RED}✗ Failed to upgrade Node.js. Please upgrade manually:${NC}"
        echo ""
        echo "Option 1 - Using snap (recommended):"
        echo "  sudo snap install node --classic --channel=20"
        echo ""
        echo "Option 2 - Using nvm:"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "  source ~/.bashrc"
        echo "  nvm install 20"
        echo "  nvm use 20"
        echo ""
        exit 1
    fi
else
    echo -e "${GREEN}✓ Node.js version is compatible (v$NODE_VERSION)${NC}"
fi
echo ""

# Step 3: Install/Update npm dependencies
echo -e "${BLUE}━━━ Step 3: Installing Dependencies ━━━${NC}"
echo "▶ Cleaning npm cache..."
npm cache clean --force 2>/dev/null || true

echo "▶ Removing old node_modules..."
rm -rf node_modules package-lock.json

echo "▶ Installing dependencies..."
npm install --legacy-peer-deps

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 4: Fix database schema
echo -e "${BLUE}━━━ Step 4: Fixing Database Schema ━━━${NC}"

# Check if we're using Neon or local PostgreSQL
if grep -q "neon.tech" .env.local 2>/dev/null || grep -q "neon.tech" .env 2>/dev/null; then
    echo "▶ Detected Neon database connection"
    echo "▶ Database fixes will be applied when you start the application"
    echo "▶ Visit http://localhost:3000/api/fix-database-schema after starting"
else
    echo "▶ Detected local PostgreSQL"
    
    # Check if PostgreSQL is running
    if sudo systemctl is-active --quiet postgresql; then
        echo -e "${GREEN}✓ PostgreSQL is running${NC}"
        
        # Apply database fixes
        if [ -f "scripts/fix-missing-schema-elements.sql" ]; then
            echo "▶ Applying database schema fixes..."
            sudo -u postgres psql -d isp_system -f scripts/fix-missing-schema-elements.sql 2>/dev/null || true
            echo -e "${GREEN}✓ Database schema updated${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ PostgreSQL is not running. Start it with: sudo systemctl start postgresql${NC}"
    fi
fi
echo ""

# Step 5: Build the application
echo -e "${BLUE}━━━ Step 5: Building Application ━━━${NC}"
echo "▶ Building Next.js application..."
npm run build

echo -e "${GREEN}✓ Build completed successfully${NC}"
echo ""

# Final instructions
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ INSTALLATION COMPLETE!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}To start the system:${NC}"
echo "  npm run dev"
echo ""
echo -e "${GREEN}Then open your browser to:${NC}"
echo "  http://localhost:3000"
echo ""
echo -e "${YELLOW}If you see database errors:${NC}"
echo "  Visit: http://localhost:3000/api/fix-database-schema"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
