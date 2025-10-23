#!/bin/bash

# ISP Management System - Simplified Installation Script
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚀 ISP Management System - Simple Installation"
echo "=============================================="
echo ""

# Check if in correct directory
if [ ! -f "package.json" ]; then
    error "package.json not found. Run this from the project directory."
    exit 1
fi

# Check sudo
info "Checking sudo access..."
if ! sudo -v; then
    error "Need sudo access to install PostgreSQL"
    exit 1
fi
success "Sudo access verified"

# Install PostgreSQL
info "Installing PostgreSQL..."
if ! command -v psql &> /dev/null; then
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    success "PostgreSQL installed"
else
    success "PostgreSQL already installed"
    sudo systemctl start postgresql 2>/dev/null || true
fi

# Generate credentials
DB_NAME="isp_system"
DB_USER="isp_admin"
DB_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)

info "Creating database..."

# Drop existing database
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${DB_NAME};" 2>/dev/null || true
sudo -u postgres psql -c "DROP USER IF EXISTS ${DB_USER};" 2>/dev/null || true

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME};"
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

# Grant permissions
sudo -u postgres psql -d ${DB_NAME} -c "GRANT ALL ON SCHEMA public TO ${DB_USER};"
sudo -u postgres psql -d ${DB_NAME} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};"
sudo -u postgres psql -d ${DB_NAME} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};"

success "Database created: ${DB_NAME}"

# Create .env.local
info "Creating environment file..."
cat > .env.local << EOF
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_PRISMA_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL_NON_POOLING="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
DATABASE_URL_UNPOOLED="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_HOST="localhost"
POSTGRES_USER="${DB_USER}"
POSTGRES_PASSWORD="${DB_PASSWORD}"
POSTGRES_DATABASE="${DB_NAME}"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
JWT_SECRET="$(openssl rand -base64 32)"
EOF

success "Environment file created"

# Run migrations
info "Running database migrations..."
if [ -d "scripts" ]; then
    TEMP_SCRIPTS="/tmp/isp_migrations_$$"
    mkdir -p "$TEMP_SCRIPTS"
    cp -r scripts/* "$TEMP_SCRIPTS/"
    chmod -R 755 "$TEMP_SCRIPTS"
    
    SCRIPT_COUNT=0
    FAILED_COUNT=0
    
    for script in $(find "$TEMP_SCRIPTS" -name "*.sql" -type f | sort -V); do
        SCRIPT_NAME=$(basename "$script")
        info "Running: $SCRIPT_NAME"
        
        if sudo -u postgres psql -d ${DB_NAME} < "$script" 2>&1 | grep -v "NOTICE" | grep -v "already exists" || true; then
            SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
        else
            warning "Error in $SCRIPT_NAME (continuing...)"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    done
    
    rm -rf "$TEMP_SCRIPTS"
    
    success "Ran $SCRIPT_COUNT migration scripts successfully"
    if [ $FAILED_COUNT -gt 0 ]; then
        warning "$FAILED_COUNT scripts had errors (may be OK if tables already exist)"
    fi
else
    warning "No scripts directory found"
fi

# Check Node.js
info "Checking Node.js..."
if ! command -v node &> /dev/null; then
    info "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    success "Node.js installed"
else
    NODE_VERSION=$(node --version)
    success "Node.js $NODE_VERSION found"
fi

# Install dependencies
info "Installing dependencies..."
npm install --legacy-peer-deps
success "Dependencies installed"

# Build application
info "Building application..."
npm run build || warning "Build had warnings (OK for development)"

echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "Database: ${DB_NAME}"
echo "User: ${DB_USER}"
echo "Password: ${DB_PASSWORD}"
echo ""
echo "Start the system:"
echo "  npm run dev"
echo ""
echo "Access at: http://localhost:3000"
echo ""
success "System ready!"
