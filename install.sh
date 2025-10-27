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
NC='\033[0m'

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

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

# Database configuration
DB_NAME="isp_system"
DB_USER="isp_admin"
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Install PostgreSQL
install_postgresql() {
    print_status "Installing PostgreSQL..."
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            sudo apt update
            sudo apt install -y postgresql postgresql-contrib
        elif [[ "$DISTRO" == "fedora" ]] || [[ "$DISTRO" == "rhel" ]] || [[ "$DISTRO" == "centos" ]]; then
            sudo dnf install -y postgresql-server postgresql-contrib
            sudo postgresql-setup --initdb
        fi
        
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
    elif [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew is not installed. Please install Homebrew first."
            exit 1
        fi
        brew install postgresql@15
        brew services start postgresql@15
    fi
    
    print_success "PostgreSQL installed successfully"
}

# Setup database
setup_database() {
    print_status "Setting up database..."
    
    sudo -u postgres psql <<'EOSQL'
CREATE USER isp_admin WITH PASSWORD 'PLACEHOLDER_PASSWORD';
CREATE DATABASE isp_system OWNER isp_admin;
GRANT ALL PRIVILEGES ON DATABASE isp_system TO isp_admin;
\c isp_system
GRANT ALL ON SCHEMA public TO isp_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO isp_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO isp_admin;
EOSQL
    
    # Update password
    sudo -u postgres psql -c "ALTER USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
    
    print_success "Database created successfully"
    
    # Create .env.local file
    print_status "Creating environment configuration..."
    
    cat > .env.local <<ENVEOF
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_PRISMA_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
DATABASE_URL_UNPOOLED="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL_NON_POOLING="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
PGHOST="localhost"
PGUSER="${DB_USER}"
PGPASSWORD="${DB_PASSWORD}"
PGDATABASE="${DB_NAME}"
PGPORT="5432"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NODE_ENV="development"
ENVEOF
    
    print_success "Environment configuration created"
    
    cat > database-credentials.txt <<CREDEOF
ISP Management System - Database Credentials
Database Name: ${DB_NAME}
Database User: ${DB_USER}
Database Password: ${DB_PASSWORD}
Connection String: postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}
CREDEOF
    
    chmod 600 database-credentials.txt
    print_success "Database credentials saved to database-credentials.txt"
}

# Install Node.js
install_nodejs() {
    print_status "Installing Node.js..."
    
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
    elif [[ "$OS" == "macos" ]]; then
        brew install node@20
        brew link node@20
    fi
    
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        print_success "Node.js $(node --version) and npm $(npm --version) installed"
    else
        print_error "Node.js installation failed"
        exit 1
    fi
}

# Check Node.js
check_nodejs() {
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            print_success "Node.js $(node --version) is already installed"
            return 0
        else
            print_warning "Node.js version is too old. Installing newer version..."
            install_nodejs
        fi
    else
        install_nodejs
    fi
}

# Install dependencies
install_dependencies() {
    print_status "Installing project dependencies..."
    rm -rf node_modules package-lock.json
    npm cache clean --force
    npm install --legacy-peer-deps
    print_success "Dependencies installed successfully"
}

# Main installation function
main() {
    echo ""
    print_status "Starting installation process..."
    echo ""
    
    print_status "Step 1/6: Checking PostgreSQL..."
    if command -v psql &> /dev/null; then
        print_success "PostgreSQL is already installed"
    else
        install_postgresql
    fi
    
    print_status "Step 2/6: Setting up database..."
    setup_database
    
    print_status "Step 3/6: Checking Node.js..."
    check_nodejs
    
    print_status "Step 4/6: Installing dependencies..."
    install_dependencies
    
    print_status "Step 5/6: Building the application..."
    npm run build
    
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    echo "Next Steps:"
    echo "1. Start the development server: npm run dev"
    echo "2. Open browser: http://localhost:3000"
    echo "3. Database credentials: ./database-credentials.txt"
    echo ""
}

main "$@"
