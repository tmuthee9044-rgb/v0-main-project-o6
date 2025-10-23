#!/bin/bash

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Node.js Fix Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Remove broken snap Node.js
echo "▶ Removing broken Node.js 12 from snap..."
sudo snap remove node 2>/dev/null || echo "  (snap node not installed or already removed)"

# Method 1: Try snap with Node.js 20
echo ""
echo "▶ Installing Node.js 20 via snap..."
if sudo snap install node --classic --channel=20; then
    echo "✓ Node.js 20 installed via snap"
    # Refresh shell to get new node
    export PATH="/snap/bin:$PATH"
    hash -r
else
    echo "✗ Snap installation failed, trying NodeSource..."
    
    # Method 2: Try NodeSource
    echo ""
    echo "▶ Installing Node.js 20 via NodeSource..."
    
    # Install curl if needed
    if ! command -v curl &> /dev/null; then
        echo "  Installing curl..."
        sudo apt-get update -qq
        sudo apt-get install -y curl
    fi
    
    # Download and run NodeSource setup
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    if [ $? -eq 0 ]; then
        echo "✓ Node.js 20 installed via NodeSource"
    else
        echo "✗ NodeSource installation failed, trying nvm..."
        
        # Method 3: Try nvm
        echo ""
        echo "▶ Installing Node.js 20 via nvm..."
        
        # Install nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # Load nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Install Node.js 20
        nvm install 20
        nvm use 20
        nvm alias default 20
        
        echo "✓ Node.js 20 installed via nvm"
    fi
fi

# Verify installation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Verifying Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Refresh shell environment
hash -r 2>/dev/null || true

# Check Node.js version
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js version: $NODE_VERSION"
    
    # Check if version is 18 or higher
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -ge 18 ]; then
        echo "✓ Node.js version is compatible (18+)"
    else
        echo "✗ Node.js version is too old (need 18+)"
        exit 1
    fi
else
    echo "✗ Node.js not found"
    exit 1
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✓ npm version: $NPM_VERSION"
else
    echo "✗ npm not found"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Node.js and npm are working correctly!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Close and reopen your terminal (or run: source ~/.bashrc)"
echo "2. Run: ./auto-install.sh"
echo ""
