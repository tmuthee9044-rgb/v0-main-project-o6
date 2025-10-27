#!/bin/bash
set -e

echo "ISP Management System - Installation"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

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

# Create .env.local
print_info "Creating environment file..."
cat > .env.local << EOF
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NODE_ENV="development"
EOF
print_success "Environment configured"

# Save credentials
cat > database-credentials.txt << EOF
Database: ${DB_NAME}
User: ${DB_USER}
Password: ${DB_PASSWORD}
URL: postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}
EOF
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

# Install dependencies
print_info "Installing npm packages..."
rm -rf node_modules package-lock.json
npm cache clean --force
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
echo "  1. npm run dev"
echo "  2. Open http://localhost:3000"
echo "  3. Credentials in: ./database-credentials.txt"
echo ""
EOF
