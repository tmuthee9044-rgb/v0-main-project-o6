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
    
    # Create database and user
    sudo -u postgres psql <<EOSQL
-- Create user
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';

-- Create database
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};

-- Connect to database and grant schema privileges
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
EOSQL
    
    print_success "Database created successfully"
    
    # Create .env.local file
    print_status "Creating environment configuration..."
    
    cat > .env.local <<ENVEOF
# Database Configuration (Local PostgreSQL)
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_PRISMA_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
DATABASE_URL_UNPOOLED="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL_NON_POOLING="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"

# Database Connection Details
PGHOST="localhost"
PGUSER="${DB_USER}"
PGPASSWORD="${DB_PASSWORD}"
PGDATABASE="${DB_NAME}"
PGPORT="5432"

# Next.js Configuration
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NODE_ENV="development"
ENVEOF
    
    print_success "Environment configuration created"
    
    # Save credentials to a separate file
    cat > database-credentials.txt <<CREDEOF
ISP Management System - Database Credentials
=============================================

Database Name: ${DB_NAME}
Database User: ${DB_USER}
Database Password: ${DB_PASSWORD}
Database Host: localhost
Database Port: 5432

Connection String:
postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}

IMPORTANT: Keep these credentials secure!
=============================================
CREDEOF
    
    chmod 600 database-credentials.txt
    print_success "Database credentials saved to database-credentials.txt"
}

# Install Node.js
install_nodejs() {
    print_status "Installing Node.js..."
    
    if [[ "$OS" == "linux" ]]; then
        # Install Node.js 20.x from NodeSource
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
        
    elif [[ "$OS" == "macos" ]]; then
        brew install node@20
        brew link node@20
    fi
    
    # Verify installation
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        print_success "Node.js $(node --version) and npm $(npm --version) installed successfully"
    else
        print_error "Node.js or npm installation failed"
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
    
    # Clean npm cache and remove old installations
    rm -rf node_modules package-lock.json
    npm cache clean --force
    
    # Install dependencies with legacy peer deps to handle React version conflicts
    npm install --legacy-peer-deps
    
    print_success "Dependencies installed successfully"
}

# Main installation function
main() {
    echo ""
    print_status "Starting installation process..."
    echo ""
    
    # Step 1: Check PostgreSQL
    print_status "Step 1/6: Checking PostgreSQL..."
    if command -v psql &> /dev/null; then
        print_success "PostgreSQL is already installed"
    else
        install_postgresql
    fi
    
    # Step 2: Setup database
    print_status "Step 2/6: Setting up database..."
    setup_database
    
    # Step 3: Check Node.js
    print_status "Step 3/6: Checking Node.js..."
    check_nodejs
    
    # Step 4: Install dependencies
    print_status "Step 4/6: Installing dependencies..."
    install_dependencies
    
    # Step 5: Build the application
    print_status "Step 5/6: Building the application..."
    npm run build
    
    # Step 6: Final instructions
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    echo "================================================="
    echo "Next Steps:"
    echo "================================================="
    echo ""
    echo "1. Start the development server:"
    echo "   npm run dev"
    echo ""
    echo "2. Open your browser and navigate to:"
    echo "   http://localhost:3000"
    echo ""
    echo "3. Database credentials have been saved to:"
    echo "   ./database-credentials.txt"
    echo ""
    echo "4. For production deployment:"
    echo "   npm run build && npm start"
    echo ""
    print_warning "IMPORTANT: Keep your database credentials secure!"
    echo "================================================="
}

# Run main function
main "$@"
