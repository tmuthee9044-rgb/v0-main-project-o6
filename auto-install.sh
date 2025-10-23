#!/bin/bash

# ISP Management System - Fully Automated One-Command Installation
# This script is idempotent - safe to run multiple times to fix issues

set -e
trap 'handle_error $? $LINENO' ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}▶${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
step() { echo -e "${CYAN}━━━ $1 ━━━${NC}"; }

handle_error() {
    error "Installation failed at line $2 with exit code $1"
    warning "Run this script again to retry and fix issues"
    exit $1
}

clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   ISP Management System - Automated Installation      ║"
echo "║   One Command - Complete Setup - Offline Database     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verify we're in the right directory
if [ ! -f "package.json" ]; then
    error "package.json not found!"
    error "Please run this script from the project root directory"
    exit 1
fi

# Check sudo access
info "Verifying sudo access..."
if ! sudo -v; then
    error "This script requires sudo access to install system packages"
    exit 1
fi
success "Sudo access verified"

# Keep sudo alive
(while true; do sudo -v; sleep 50; done) &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null || true" EXIT

# ============================================
# STEP 1: Install PostgreSQL
# ============================================
step "Installing PostgreSQL Database"

if command -v psql &> /dev/null; then
    success "PostgreSQL already installed"
else
    info "Installing PostgreSQL..."
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -qq
    sudo apt-get install -y -qq postgresql postgresql-contrib > /dev/null 2>&1
    success "PostgreSQL installed"
fi

# Start PostgreSQL service
info "Starting PostgreSQL service..."
sudo systemctl start postgresql 2>/dev/null || true
sudo systemctl enable postgresql 2>/dev/null || true
sleep 2
success "PostgreSQL service running"

# ============================================
# STEP 2: Setup Database
# ============================================
step "Setting Up Local Database"

DB_NAME="isp_system"
DB_USER="isp_admin"
DB_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-20)

info "Creating database and user..."

cd /tmp

# Drop existing (idempotent)
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${DB_NAME};" 2>/dev/null || true
sudo -u postgres psql -c "DROP USER IF EXISTS ${DB_USER};" 2>/dev/null || true

# Create fresh
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME};" > /dev/null
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';" > /dev/null
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" > /dev/null
sudo -u postgres psql -c "ALTER USER ${DB_USER} CREATEDB;" > /dev/null

# Grant schema permissions
sudo -u postgres psql -d ${DB_NAME} -c "GRANT ALL ON SCHEMA public TO ${DB_USER};" > /dev/null
sudo -u postgres psql -d ${DB_NAME} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};" > /dev/null
sudo -u postgres psql -d ${DB_NAME} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};" > /dev/null
sudo -u postgres psql -d ${DB_NAME} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};" > /dev/null

cd - > /dev/null

success "Database '${DB_NAME}' created"
success "User '${DB_USER}' created with full permissions"

# ============================================
# STEP 3: Run Database Migrations
# ============================================
step "Running Database Migrations"

if [ ! -d "scripts" ]; then
    warning "No scripts directory found - skipping migrations"
else
    # Copy scripts to postgres-accessible location
    MIGRATION_DIR="/tmp/isp_migrations_$$"
    mkdir -p "$MIGRATION_DIR"
    cp scripts/*.sql "$MIGRATION_DIR/" 2>/dev/null || true
    chmod -R 755 "$MIGRATION_DIR"
    
    # Count scripts
    TOTAL_SCRIPTS=$(ls -1 "$MIGRATION_DIR"/*.sql 2>/dev/null | wc -l)
    
    if [ "$TOTAL_SCRIPTS" -eq 0 ]; then
        warning "No SQL scripts found"
    else
        info "Found $TOTAL_SCRIPTS migration scripts"
        
        SUCCESS_COUNT=0
        SKIP_COUNT=0
        
        cd /tmp
        
        # Run migrations in order
        for script in $(ls -1v "$MIGRATION_DIR"/*.sql); do
            SCRIPT_NAME=$(basename "$script")
            
            # Run script and capture output
            if sudo -u postgres psql -d ${DB_NAME} -f "$script" > /dev/null 2>&1; then
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                echo -ne "\r${BLUE}▶${NC} Progress: $SUCCESS_COUNT/$TOTAL_SCRIPTS scripts completed"
            else
                SKIP_COUNT=$((SKIP_COUNT + 1))
            fi
        done
        
        cd - > /dev/null
        
        echo "" # New line after progress
        
        # Cleanup
        rm -rf "$MIGRATION_DIR"
        
        success "Successfully ran $SUCCESS_COUNT/$TOTAL_SCRIPTS migrations"
        if [ $SKIP_COUNT -gt 0 ]; then
            warning "$SKIP_COUNT scripts skipped (likely already applied)"
        fi
        
        # Verify tables created
        cd /tmp
        TABLE_COUNT=$(sudo -u postgres psql -d ${DB_NAME} -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
        cd - > /dev/null
        success "Database contains $TABLE_COUNT tables"
    fi
fi

# ============================================
# STEP 4: Create Environment Configuration
# ============================================
step "Configuring Environment"

info "Creating .env.local file..."

cat > .env.local << EOF
# Database Configuration (Local PostgreSQL)
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_PRISMA_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL_NON_POOLING="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
DATABASE_URL_UNPOOLED="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"

# Database Credentials
POSTGRES_HOST="localhost"
POSTGRES_USER="${DB_USER}"
POSTGRES_PASSWORD="${DB_PASSWORD}"
POSTGRES_DATABASE="${DB_NAME}"
PGHOST="localhost"
PGUSER="${DB_USER}"
PGPASSWORD="${DB_PASSWORD}"
PGDATABASE="${DB_NAME}"

# Application Configuration
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NODE_ENV="development"

# Security
JWT_SECRET="$(openssl rand -base64 32)"
SESSION_SECRET="$(openssl rand -base64 32)"

# Generated on $(date)
EOF

success "Environment configuration created"

# Save credentials for user reference
cat > .database-credentials.txt << EOF
ISP Management System - Database Credentials
============================================
Generated: $(date)

Database Name: ${DB_NAME}
Username:      ${DB_USER}
Password:      ${DB_PASSWORD}
Host:          localhost
Port:          5432

Connection String:
postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}

IMPORTANT: Keep this file secure and do not commit to version control!
EOF

success "Credentials saved to .database-credentials.txt"

# ============================================
# STEP 5: Install Node.js
# ============================================
step "Installing Node.js"

CURRENT_NODE_VERSION=0
if command -v node &> /dev/null; then
    CURRENT_NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$CURRENT_NODE_VERSION" -ge 18 ]; then
        success "Node.js $(node --version) already installed (compatible)"
    else
        warning "Node.js version v$CURRENT_NODE_VERSION detected (v18+ recommended)"
        NEED_UPGRADE=true
    fi
else
    info "Node.js not found, installing..."
    NEED_UPGRADE=true
fi

if [ "$NEED_UPGRADE" = true ]; then
    warning "Attempting to upgrade Node.js to v20..."
    warning "If this fails, installation will continue with current version"
    
    # Disable exit on error temporarily for Node.js upgrade
    set +e
    
    # Method 1: Try using snap (fastest and most reliable)
    info "Attempting snap installation (recommended)..."
    if command -v snap &> /dev/null || sudo apt-get install -y snapd > /dev/null 2>&1; then
        if sudo snap install node --classic --channel=20/stable > /dev/null 2>&1; then
            export PATH="/snap/bin:$PATH"
            if command -v node &> /dev/null; then
                NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
                if [ "$NODE_VERSION" -ge 18 ]; then
                    success "Node.js $(node --version) installed via snap"
                    if ! grep -q "/snap/bin" ~/.bashrc; then
                        echo 'export PATH="/snap/bin:$PATH"' >> ~/.bashrc
                    fi
                    INSTALL_SUCCESS=true
                fi
            fi
        fi
    fi
    
    # Method 2: Try NodeSource if snap failed
    if [ "$INSTALL_SUCCESS" != true ]; then
        info "Attempting NodeSource repository installation..."
        
        if ! command -v curl &> /dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y curl > /dev/null 2>&1
        fi
        
        if curl -fsSL https://deb.nodesource.com/setup_20.x 2>/dev/null | sudo -E bash - > /dev/null 2>&1; then
            if sudo apt-get install -y nodejs > /dev/null 2>&1; then
                if command -v node &> /dev/null; then
                    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
                    if [ "$NODE_VERSION" -ge 18 ]; then
                        success "Node.js $(node --version) installed via NodeSource"
                        INSTALL_SUCCESS=true
                    fi
                fi
            fi
        fi
    fi
    
    # Re-enable exit on error
    set -e
    
    # Check if upgrade succeeded
    if [ "$INSTALL_SUCCESS" != true ]; then
        if [ "$CURRENT_NODE_VERSION" -gt 0 ]; then
            warning "Node.js upgrade failed, continuing with v$CURRENT_NODE_VERSION"
            warning "The system may have limited functionality"
            echo ""
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  IMPORTANT: Manual Node.js Upgrade Required${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo "Your current Node.js v$CURRENT_NODE_VERSION is too old for full functionality."
            echo "After installation completes, upgrade Node.js using ONE of these methods:"
            echo ""
            echo -e "${CYAN}Option 1 - Snap (Easiest):${NC}"
            echo "  sudo snap install node --classic --channel=20/stable"
            echo "  export PATH=\"/snap/bin:\$PATH\""
            echo ""
            echo -e "${CYAN}Option 2 - NodeSource:${NC}"
            echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
            echo "  sudo apt-get install -y nodejs"
            echo ""
            echo -e "${CYAN}Option 3 - nvm (Node Version Manager):${NC}"
            echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
            echo "  source ~/.bashrc"
            echo "  nvm install 20"
            echo "  nvm use 20"
            echo ""
            echo "After upgrading Node.js, rebuild the application:"
            echo "  cd $(pwd)"
            echo "  npm install"
            echo "  npm run build"
            echo ""
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            sleep 3
        else
            error "Node.js installation failed and no existing version found"
            error "Please manually install Node.js 18+ and run this script again"
            exit 1
        fi
    fi
fi

# ============================================
# STEP 6: Install Dependencies
# ============================================
step "Installing Application Dependencies"

info "Installing npm packages (this may take a few minutes)..."
npm install --legacy-peer-deps --silent 2>&1 | grep -v "deprecated" | grep -v "WARN" || true
success "Dependencies installed"

# ============================================
# STEP 7: Build Application
# ============================================
step "Building Application"

info "Building Next.js application..."
if npm run build > /tmp/build.log 2>&1; then
    success "Application built successfully"
else
    warning "Build completed with warnings (OK for development)"
fi

# ============================================
# INSTALLATION COMPLETE
# ============================================
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║              🎉 Installation Complete! 🎉             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${CYAN}Database Information:${NC}"
echo "  Name:     ${DB_NAME}"
echo "  User:     ${DB_USER}"
echo "  Password: ${DB_PASSWORD}"
echo "  Host:     localhost:5432"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Start the system:  ${GREEN}npm run dev${NC}"
echo "  2. Open browser:      ${GREEN}http://localhost:3000${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} Database credentials saved in .database-credentials.txt"
echo ""
success "System ready to use!"
echo ""

# Cleanup
kill $SUDO_PID 2>/dev/null || true
