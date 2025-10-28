#!/bin/bash

# ISP Management System - Simple Installation Script
# This script installs PostgreSQL locally and sets up the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}ISP Management System - Installation${NC}"
echo "========================================"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run as root${NC}"
   exit 1
fi

# Install PostgreSQL
echo -e "\n${YELLOW}[1/5] Installing PostgreSQL...${NC}"
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-contrib
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
elif command -v brew &> /dev/null; then
    brew install postgresql@15
    brew services start postgresql@15
else
    echo -e "${RED}Unsupported OS. Please install PostgreSQL manually.${NC}"
    exit 1
fi

# Setup database
echo -e "\n${YELLOW}[2/5] Setting up database...${NC}"
DB_NAME="isp_system"
DB_USER="isp_admin"
DB_PASSWORD=$(openssl rand -base64 12)

sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" 2>/dev/null || true

# Create .env.local
echo -e "\n${YELLOW}[3/5] Creating environment file...${NC}"
cat > .env.local << 'ENVEOF'
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}
POSTGRES_URL=postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}
ENVEOF

sed -i "s/\${DB_USER}/${DB_USER}/g" .env.local
sed -i "s/\${DB_PASSWORD}/${DB_PASSWORD}/g" .env.local
sed -i "s/\${DB_NAME}/${DB_NAME}/g" .env.local

echo -e "${GREEN}✓ Environment file created${NC}"

# Install Node.js if needed
echo -e "\n${YELLOW}[4/5] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Install dependencies
echo -e "\n${YELLOW}[5/5] Installing dependencies...${NC}"
rm -rf node_modules package-lock.json .next
npm cache clean --force
npm install --legacy-peer-deps

# Save credentials
cat > database-credentials.txt << 'CREDEOF'
Database Credentials
====================
Database: ${DB_NAME}
Username: ${DB_USER}
Password: ${DB_PASSWORD}
Connection: postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}
CREDEOF

sed -i "s/\${DB_NAME}/${DB_NAME}/g" database-credentials.txt
sed -i "s/\${DB_USER}/${DB_USER}/g" database-credentials.txt
sed -i "s/\${DB_PASSWORD}/${DB_PASSWORD}/g" database-credentials.txt

echo -e "\n${GREEN}✓ Installation complete!${NC}"
echo -e "\nDatabase credentials saved to: database-credentials.txt"
echo -e "\nTo start the application:"
echo -e "  npm run dev"
echo -e "\nThe application will be available at: http://localhost:3000"
