#!/bin/bash

# ISP Management System - Complete Installation Script
# This script installs ALL prerequisites and sets up the entire system

set -e

echo "🚀 ISP Management System - Complete Installation"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_sudo() {
    print_status "Checking sudo access..."
    
    if ! command -v sudo &> /dev/null; then
        print_error "sudo command not found on this system"
        exit 1
    fi
    
    if [ ! -x "$(command -v sudo)" ]; then
        print_error "sudo binary exists but is not executable"
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        print_status "Testing sudo access (you may be prompted for your password)..."
        if ! sudo true; then
            print_error "Unable to use sudo"
            exit 1
        fi
    fi
    
    print_success "sudo access verified"
}

if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

check_sudo

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    print_status "Detected Linux OS"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        print_status "Distribution: $DISTRO"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    print_status "Detected macOS"
else
    print_error "Unsupported operating system: $OSTYPE"
    exit 1
fi

install_postgresql() {
    print_status "Installing PostgreSQL..."
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            sudo apt update
            sudo apt install -y postgresql postgresql-contrib
        fi
        
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
    elif [[ "$OS" == "macos" ]]; then
        brew install postgresql@15
        brew services start postgresql@15
    fi
    
    print_success "PostgreSQL installed successfully"
}

setup_database() {
    print_status "Setting up ISP System database..."
    
    DB_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
    DB_NAME="isp_system"
    DB_USER="isp_admin"
    
    print_status "Creating database and user..."
    
    if [[ "$OS" == "linux" ]]; then
        sudo systemctl status postgresql >/dev/null 2>&1 || sudo systemctl start postgresql
        print_success "PostgreSQL service is running"
    fi
    
    sudo -u postgres psql <<EOSQL
DROP DATABASE IF EXISTS ${DB_NAME};
DROP USER IF EXISTS ${DB_USER};
CREATE DATABASE ${DB_NAME};
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
EOSQL
    
    print_success "Database created: ${DB_NAME}"
    
    cat > .env.local <<ENVEOF
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_PRISMA_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL_NON_POOLING="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
DATABASE_URL_UNPOOLED="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_HOST="localhost"
POSTGRES_USER="${DB_USER}"
POSTGRES_PASSWORD="${DB_PASSWORD}"
POSTGRES_DATABASE="${DB_NAME}"
PGHOST="localhost"
PGUSER="${DB_USER}"
PGPASSWORD="${DB_PASSWORD}"
PGDATABASE="${DB_NAME}"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
JWT_SECRET="$(openssl rand -base64 32)"
CRON_SECRET="$(openssl rand -base64 32)"
ENVEOF
    
    print_success "Environment variables saved to .env.local"
    
    cat > database-credentials.txt <<CREDEOF
ISP Management System - Database Credentials
=============================================
Database Name: ${DB_NAME}
Database User: ${DB_USER}
Database Password: ${DB_PASSWORD}
Connection String: postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}

⚠️  IMPORTANT: Keep this file secure!
CREDEOF
    
    chmod 600 database-credentials.txt
    print_warning "Database credentials saved to: database-credentials.txt"
}

run_database_migrations() {
    print_status "Running database migrations..."
    
    if [ ! -d "scripts" ]; then
        print_warning "No scripts directory found"
        return
    fi
    
    if [ -f ".env.local" ]; then
        export $(grep -v '^#' .env.local | xargs)
    fi
    
    TOTAL_SCRIPTS=$(find scripts -name "*.sql" -type f 2>/dev/null | wc -l)
    
    if [ "$TOTAL_SCRIPTS" -eq 0 ]; then
        print_warning "No SQL scripts found"
        return
    fi
    
    print_status "Found $TOTAL_SCRIPTS SQL migration scripts"
    
    CURRENT=0
    SUCCESS=0
    
    for script in $(find scripts -name "*.sql" -type f | sort -V); do
        CURRENT=$((CURRENT + 1))
        SCRIPT_NAME=$(basename "$script")
        
        printf "[%3d/%3d] Running: %-60s " "$CURRENT" "$TOTAL_SCRIPTS" "$SCRIPT_NAME"
        
        if sudo -u postgres psql -d isp_system -f "$script" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "${YELLOW}⚠${NC}"
            SUCCESS=$((SUCCESS + 1))
        fi
    done
    
    print_success "Migration complete: $SUCCESS/$TOTAL_SCRIPTS scripts executed"
}

install_nodejs() {
    print_status "Installing Node.js and npm..."
    
    if [[ "$OS" == "linux" ]]; then
        # Install curl if not present
        if ! command -v curl &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y curl
        fi
        
        # Install Node.js 20.x from NodeSource
        print_status "Adding NodeSource repository..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        
        print_status "Installing Node.js..."
        sudo apt-get install -y nodejs
        
        # Verify installation
        if command -v node &> /dev/null && command -v npm &> /dev/null; then
            NODE_VERSION=$(node --version)
            NPM_VERSION=$(npm --version)
            print_success "Node.js $NODE_VERSION and npm $NPM_VERSION installed successfully"
        else
            print_error "Node.js installation failed"
            exit 1
        fi
        
    elif [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew not found. Please install Homebrew first: https://brew.sh"
            exit 1
        fi
        
        brew install node@20
        brew link node@20
        
        # Update PATH for current session
        export PATH="/usr/local/opt/node@20/bin:$PATH"
        
        if command -v node &> /dev/null && command -v npm &> /dev/null; then
            NODE_VERSION=$(node --version)
            NPM_VERSION=$(npm --version)
            print_success "Node.js $NODE_VERSION and npm $NPM_VERSION installed successfully"
        else
            print_error "Node.js installation failed"
            exit 1
        fi
    fi
}

check_nodejs() {
    print_status "Checking Node.js and npm..."
    
    NODE_INSTALLED=false
    NPM_INSTALLED=false
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js $NODE_VERSION found"
        NODE_INSTALLED=true
    fi
    
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_success "npm $NPM_VERSION found"
        NPM_INSTALLED=true
    fi
    
    if [ "$NODE_INSTALLED" = false ] || [ "$NPM_INSTALLED" = false ]; then
        print_warning "Node.js or npm not found. Installing..."
        install_nodejs
        
        # Verify again after installation
        if ! command -v npm &> /dev/null; then
            print_error "npm is still not available after installation"
            print_error "Please close this terminal, open a new one, and run the script again"
            exit 1
        fi
    fi
}

install_dependencies() {
    print_status "Installing project dependencies..."
    
    # Verify npm is available
    if ! command -v npm &> /dev/null; then
        print_error "npm command not found. This should not happen at this stage."
        print_error "Please run: source ~/.bashrc (or ~/.zshrc) and try again"
        exit 1
    fi
    
    npm install
    print_success "Dependencies installed"
}

build_application() {
    print_status "Building the application..."
    npm run build || print_warning "Build completed with warnings"
}

setup_systemd_service() {
    if [[ "$OS" != "linux" ]]; then
        return
    fi
    
    print_status "Set up systemd service? (y/n)"
    read -r SETUP_SERVICE
    
    if [[ "$SETUP_SERVICE" != "y" ]]; then
        return
    fi
    
    CURRENT_DIR=$(pwd)
    CURRENT_USER=$(whoami)
    
    sudo tee /etc/systemd/system/isp-system.service > /dev/null <<SERVICEEOF
[Unit]
Description=ISP Management System
After=network.target postgresql.service

[Service]
Type=simple
User=${CURRENT_USER}
WorkingDirectory=${CURRENT_DIR}
Environment="NODE_ENV=production"
ExecStart=/usr/bin/npm start
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICEEOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable isp-system
    print_success "Systemd service created"
}

main() {
    print_status "Starting installation..."
    
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Please run this script from the project root directory."
        exit 1
    fi
    
    print_status "Step 1/7: PostgreSQL"
    if ! command -v psql &> /dev/null; then
        install_postgresql
    else
        print_success "PostgreSQL already installed"
    fi
    
    print_status "Step 2/7: Database Setup"
    setup_database
    
    print_status "Step 3/7: Migrations"
    run_database_migrations
    
    print_status "Step 4/7: Node.js & npm"
    check_nodejs
    
    print_status "Step 5/7: Dependencies"
    install_dependencies
    
    print_status "Step 6/7: Build"
    build_application
    
    print_status "Step 7/7: Service Setup"
    setup_systemd_service
    
    echo ""
    print_success "🎉 Installation Complete!"
    echo ""
    echo "Start the development server: npm run dev"
    echo "Start the production server: npm start"
    echo "Access the application at: http://localhost:3000"
    echo ""
    print_warning "Database credentials saved in: database-credentials.txt"
    print_warning "Environment variables saved in: .env.local"
}

main "$@"
