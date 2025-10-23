#!/bin/bash

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                    EMERGENCY NODE.JS FIX SCRIPT                              "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This script will:"
echo "  1. Remove broken Node.js 12 installation"
echo "  2. Install Node.js 20 properly"
echo "  3. Install project dependencies"
echo "  4. Build and start the application"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Remove broken snap Node.js
echo "▶ Removing broken Node.js 12 snap installation..."
sudo snap remove node 2>/dev/null || echo "  (snap node not installed or already removed)"

# Step 2: Install Node.js 20 using NodeSource
echo ""
echo "▶ Installing Node.js 20 from NodeSource..."
if command -v curl &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
elif command -v wget &> /dev/null; then
    wget -qO- https://deb.nodesource.com/setup_20.x | sudo -E bash -
else
    echo "✗ ERROR: Neither curl nor wget is available!"
    echo "  Please install curl first: sudo apt-get install -y curl"
    exit 1
fi

sudo apt-get install -y nodejs

# Step 3: Verify installation
echo ""
echo "▶ Verifying Node.js installation..."
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)

echo "  ✓ Node.js: $NODE_VERSION"
echo "  ✓ npm: $NPM_VERSION"

# Check if Node.js version is acceptable
MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
if [ "$MAJOR_VERSION" -lt 18 ]; then
    echo "✗ ERROR: Node.js version is still too old ($NODE_VERSION)"
    echo "  Required: v18 or higher"
    exit 1
fi

# Step 4: Navigate to correct project directory
echo ""
echo "▶ Finding project root directory..."

# Find the first (outermost) isp-system directory with package.json
PROJECT_ROOT=""
CURRENT_DIR=$(pwd)

# Go up until we find the first isp-system with package.json
while [ "$CURRENT_DIR" != "/" ]; do
    if [ -f "$CURRENT_DIR/package.json" ] && [[ "$CURRENT_DIR" == *"isp-system"* ]]; then
        PROJECT_ROOT="$CURRENT_DIR"
    fi
    CURRENT_DIR=$(dirname "$CURRENT_DIR")
done

if [ -z "$PROJECT_ROOT" ]; then
    # If not found going up, try current directory
    if [ -f "package.json" ]; then
        PROJECT_ROOT=$(pwd)
    else
        echo "✗ ERROR: Could not find package.json"
        exit 1
    fi
fi

echo "  ✓ Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Step 5: Clean and install dependencies
echo ""
echo "▶ Cleaning old dependencies..."
rm -rf node_modules package-lock.json .next

echo ""
echo "▶ Installing dependencies (this may take 2-3 minutes)..."
npm install --legacy-peer-deps

# Step 6: Build the application
echo ""
echo "▶ Building application..."
npm run build

# Step 7: Success message
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                         ✓ INSTALLATION COMPLETE!                             "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To start the application, run:"
echo "  npm run dev"
echo ""
echo "Then open your browser to: http://localhost:3000"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
