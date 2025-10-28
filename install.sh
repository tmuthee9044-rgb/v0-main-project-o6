#!/bin/bash
set -e

echo "ISP Management System - Installation"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Check not root
[[ $EUID -eq 0 ]] && print_error "Don't run as root"

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    print_error "Unsupported OS: $OSTYPE"
fi

print_info "Detected OS: $OS"

# Database config
DB_NAME="isp_system"
DB_USER="isp_admin"
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Install PostgreSQL
print_info "Installing PostgreSQL..."
if [[ "$OS" == "linux" ]]; then
    sudo apt update && sudo apt install -y postgresql postgresql-contrib
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
elif [[ "$OS" == "macos" ]]; then
    brew install postgresql@15
    brew services start postgresql@15
fi
print_success "PostgreSQL installed"

# Create database
print_info "Creating database..."
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
print_success "Database created"

print_info "Creating environment file..."
cat > .env.local << 'ENVEOF'
DATABASE_URL=postgresql://DB_USER_PLACEHOLDER:DB_PASSWORD_PLACEHOLDER@localhost:5432/DB_NAME_PLACEHOLDER
POSTGRES_URL=postgresql://DB_USER_PLACEHOLDER:DB_PASSWORD_PLACEHOLDER@localhost:5432/DB_NAME_PLACEHOLDER
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
ENVEOF

sed -i.bak "s/DB_USER_PLACEHOLDER/${DB_USER}/g" .env.local
sed -i.bak "s/DB_PASSWORD_PLACEHOLDER/${DB_PASSWORD}/g" .env.local
sed -i.bak "s/DB_NAME_PLACEHOLDER/${DB_NAME}/g" .env.local
rm -f .env.local.bak

print_success "Environment configured"

# Save credentials
cat > database-credentials.txt << 'CREDEOF'
ISP Management System - Database Credentials
=============================================
Database: DB_NAME_PLACEHOLDER
User: DB_USER_PLACEHOLDER
Password: DB_PASSWORD_PLACEHOLDER
Connection URL: postgresql://DB_USER_PLACEHOLDER:DB_PASSWORD_PLACEHOLDER@localhost:5432/DB_NAME_PLACEHOLDER

IMPORTANT: Keep this file secure and do not commit it to version control.
CREDEOF

sed -i.bak "s/DB_NAME_PLACEHOLDER/${DB_NAME}/g" database-credentials.txt
sed -i.bak "s/DB_USER_PLACEHOLDER/${DB_USER}/g" database-credentials.txt
sed -i.bak "s/DB_PASSWORD_PLACEHOLDER/${DB_PASSWORD}/g" database-credentials.txt
rm -f database-credentials.txt.bak

chmod 600 database-credentials.txt
print_success "Credentials saved to database-credentials.txt"

# Install Node.js
if ! command -v node &> /dev/null; then
    print_info "Installing Node.js..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
    elif [[ "$OS" == "macos" ]]; then
        brew install node@20
    fi
    print_success "Node.js installed"
else
    print_success "Node.js already installed: $(node --version)"
fi

# Verify npm is available
if ! command -v npm &> /dev/null; then
    print_error "npm not found. Please install Node.js with npm."
fi

print_info "npm version: $(npm --version)"

print_info "Installing npm packages..."
print_warning "Cleaning cached files..."
rm -rf node_modules package-lock.json .next
npm cache clean --force

print_info "Installing dependencies (this may take a few minutes)..."
npm install --legacy-peer-deps

print_success "Dependencies installed"

# Build
print_info "Building application..."
npm run build
print_success "Build complete"

echo ""
print_success "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Start the development server:"
echo "     npm run dev"
echo ""
echo "  2. Open your browser to:"
echo "     http://localhost:3000"
echo ""
echo "  3. Database credentials saved in:"
echo "     ./database-credentials.txt"
echo ""
echo "Note: The system is configured for offline PostgreSQL operation."
echo ""
