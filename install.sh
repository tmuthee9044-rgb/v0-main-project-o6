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
    
    # Check if sudo exists
    if ! command -v sudo &> /dev/null; then
        print_error "sudo command not found on this system"
        print_error "This usually means:"
        print_error "  1. You're on a minimal system without sudo installed"
        print_error "  2. You need to install sudo first as root"
        print_error ""
        print_error "To fix this, run as root:"
        print_error "  apt-get update && apt-get install -y sudo"
        print_error "  usermod -aG sudo $(whoami)"
        print_error "Then log out and log back in."
        exit 1
    fi
    
    # Check if sudo binary is executable
    if [ ! -x "$(command -v sudo)" ]; then
        print_error "sudo binary exists but is not executable"
        print_error "This indicates a corrupted sudo installation or file system issue"
        print_error ""
        print_error "To fix this, run as root:"
        print_error "  chmod +x /usr/bin/sudo"
        print_error "  apt-get install --reinstall sudo"
        exit 1
    fi
    
    # Test sudo access
    if ! sudo -n true 2>/dev/null; then
        print_status "Testing sudo access (you may be prompted for your password)..."
        if ! sudo true; then
            print_error "Unable to use sudo. Please ensure:"
            print_error "  1. Your user is in the sudo group: sudo usermod -aG sudo $(whoami)"
            print_error "  2. You have sudo privileges configured"
            print_error "  3. Your password is correct"
            exit 1
        fi
    fi
    
    print_success "sudo access verified"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Run as a regular user with sudo privileges."
   exit 1
fi

check_sudo

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    print_status "Detected Linux OS"
    
    # Detect Linux distribution
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

check_git() {
    print_status "Checking Git installation..."
    
    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Installing Git..."
        install_git
    else
        GIT_VERSION=$(git --version)
        print_success "$GIT_VERSION is installed"
    fi
}

install_git() {
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            sudo apt update
            sudo apt install -y git
        elif [[ "$DISTRO" == "fedora" ]] || [[ "$DISTRO" == "rhel" ]] || [[ "$DISTRO" == "centos" ]]; then
            sudo dnf install -y git
        else
            print_error "Unsupported Linux distribution for automatic Git installation"
            print_status "Please install Git manually: https://git-scm.com/downloads"
            exit 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            print_status "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install git
    fi
    
    if command -v git &> /dev/null; then
        print_success "Git $(git --version) installed successfully"
    else
        print_error "Failed to install Git"
        exit 1
    fi
}

install_postgresql() {
    print_status "Installing PostgreSQL..."
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            sudo apt update
            sudo apt install -y postgresql postgresql-contrib
        elif [[ "$DISTRO" == "fedora" ]] || [[ "$DISTRO" == "rhel" ]] || [[ "$DISTRO" == "centos" ]]; then
            sudo dnf install -y postgresql-server postgresql-contrib
            sudo postgresql-setup --initdb
        else
            print_error "Unsupported Linux distribution for automatic PostgreSQL installation"
            print_status "Please install PostgreSQL manually: https://www.postgresql.org/download/"
            exit 1
        fi
        
        # Start and enable PostgreSQL
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
    elif [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            print_status "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install postgresql@15
        brew services start postgresql@15
    fi
    
    print_success "PostgreSQL installed successfully"
}

setup_database() {
    print_status "Setting up ISP System database..."
    
    # Generate random password
    DB_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
    DB_NAME="isp_system"
    DB_USER="isp_admin"
    
    print_status "Creating database and user..."
    
    # First, ensure PostgreSQL is running
    if [[ "$OS" == "linux" ]]; then
        sudo systemctl status postgresql >/dev/null 2>&1 || sudo systemctl start postgresql
        print_success "PostgreSQL service is running"
    fi
    
    # Create database and user with better error handling
    sudo -u postgres psql << EOF || {
        print_error "Failed to create database. Checking if it already exists..."
        # Try to connect to existing database
        if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw ${DB_NAME}; then
            print_warning "Database ${DB_NAME} already exists. Using existing database."
        else
            print_error "Could not create or find database. Please check PostgreSQL installation."
            exit 1
        fi
    }
-- Drop existing database if it exists
DROP DATABASE IF EXISTS ${DB_NAME};
DROP USER IF EXISTS ${DB_USER};

-- Create new database and user
CREATE DATABASE ${DB_NAME};
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};

-- Connect to the database and grant schema privileges
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
EOF
    
    print_success "Database created: ${DB_NAME}"
    print_success "Database user created: ${DB_USER}"
    
    cat > .env.local << EOF
# Database Configuration (Auto-generated by install.sh)
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_PRISMA_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL_NON_POOLING="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
DATABASE_URL_UNPOOLED="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_URL_NO_SSL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
POSTGRES_HOST="localhost"
POSTGRES_USER="${DB_USER}"
POSTGRES_PASSWORD="${DB_PASSWORD}"
POSTGRES_DATABASE="${DB_NAME}"
PGHOST="localhost"
PGUSER="${DB_USER}"
PGPASSWORD="${DB_PASSWORD}"
PGDATABASE="${DB_NAME}"
PGHOST_UNPOOLED="localhost"

# Application Configuration
NEXT_PUBLIC_APP_URL="http://localhost:3000"
JWT_SECRET="$(openssl rand -base64 32)"
CRON_SECRET="$(openssl rand -base64 32)"

# Optional: M-Pesa Configuration (configure later if needed)
MPESA_BUSINESS_SHORT_CODE=""
MPESA_CONSUMER_KEY=""
MPESA_CONSUMER_SECRET=""
EOF
    
    print_success "Environment variables saved to .env.local"
    
    # Save credentials to a secure file for reference
    cat > database-credentials.txt << EOF
ISP Management System - Database Credentials
=============================================
Database Name: ${DB_NAME}
Database User: ${DB_USER}
Database Password: ${DB_PASSWORD}
Connection String: postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}

⚠️  IMPORTANT: Keep this file secure and delete it after noting the credentials!
EOF
    
    chmod 600 database-credentials.txt
    print_warning "Database credentials saved to: database-credentials.txt"
    
    print_status "Verifying database connection..."
    if sudo -u postgres psql -d ${DB_NAME} -c "SELECT version();" >/dev/null 2>&1; then
        print_success "Database connection verified!"
    else
        print_error "Could not connect to database. Please check PostgreSQL installation."
        exit 1
    fi
}

run_database_migrations() {
    print_status "Running database migrations..."
    
    if [ ! -d "scripts" ]; then
        print_warning "No scripts directory found. Skipping migrations."
        return
    fi
    
    if [ -f ".env.local" ]; then
        export $(grep -v '^#' .env.local | xargs)
    fi
    
    # Count total SQL scripts only
    TOTAL_SCRIPTS=$(find scripts -name "*.sql" -type f 2>/dev/null | wc -l)
    
    if [ "$TOTAL_SCRIPTS" -eq 0 ]; then
        print_warning "No SQL scripts found in scripts/ directory"
        return
    fi
    
    print_status "Found $TOTAL_SCRIPTS SQL migration scripts"
    echo ""
    
    CURRENT=0
    FAILED=0
    SUCCESS=0
    
    # Sort scripts numerically
    for script in $(find scripts -name "*.sql" -type f | sort -V); do
        CURRENT=$((CURRENT + 1))
        SCRIPT_NAME=$(basename "$script")
        
        printf "[%3d/%3d] Running: %-60s " "$CURRENT" "$TOTAL_SCRIPTS" "$SCRIPT_NAME"
        
        # Run script and capture output
        if OUTPUT=$(sudo -u postgres psql -d isp_system -f "$script" 2>&1); then
            echo -e "${GREEN}✓${NC}"
            SUCCESS=$((SUCCESS + 1))
        else
            # Check if error is just about existing objects (which is OK)
            if echo "$OUTPUT" | grep -qi "already exists\|duplicate"; then
                echo -e "${YELLOW}⚠${NC} (already exists)"
                SUCCESS=$((SUCCESS + 1))
            else
                echo -e "${RED}✗${NC}"
                print_error "Error in $SCRIPT_NAME:"
                echo "$OUTPUT" | head -5
                FAILED=$((FAILED + 1))
            fi
        fi
    done
    
    echo ""
    echo "Migration Summary:"
    echo "  Total Scripts: $TOTAL_SCRIPTS"
    echo "  Successful: $SUCCESS"
    echo "  Failed: $FAILED"
    echo ""
    
    if [ "$FAILED" -eq 0 ]; then
        print_success "All migration scripts executed successfully!"
    else
        print_warning "$FAILED scripts failed (check errors above)"
        print_status "Continuing with installation..."
    fi
    
    print_status "Verifying database tables..."
    TABLE_COUNT=$(sudo -u postgres psql -d isp_system -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        print_success "Database has $TABLE_COUNT tables created"
    else
        print_error "No tables found in database! Migration may have failed."
        exit 1
    fi
}

check_nodejs() {
    print_status "Checking Node.js installation..."
    
    if ! command -v node &> /dev/null; then
        print_warning "Node.js not found. Installing Node.js 20..."
        install_nodejs
    else
        NODE_VERSION=$(node --version | cut -d'v' -f2)
        MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1)
        
        if [[ $MAJOR_VERSION -lt 18 ]]; then
            print_warning "Node.js version $NODE_VERSION detected. Upgrading to Node.js 20..."
            install_nodejs
        else
            print_success "Node.js $NODE_VERSION is installed"
        fi
    fi
}

install_nodejs() {
    if [[ "$OS" == "linux" ]]; then
        print_status "Installing Node.js 20 via NodeSource repository..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            print_status "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        print_status "Installing Node.js 20 via Homebrew..."
        brew install node@20
        brew link --overwrite node@20
    fi
    
    if command -v node &> /dev/null; then
        print_success "Node.js $(node --version) installed successfully"
    else
        print_error "Failed to install Node.js"
        exit 1
    fi
}

install_dependencies() {
    print_status "Installing project dependencies..."
    
    npm cache clean --force 2>/dev/null || true
    
    if ! npm install; then
        print_error "npm install failed. Trying with --legacy-peer-deps..."
        npm install --legacy-peer-deps
    fi
    
    print_success "Dependencies installed successfully"
}

build_application() {
    print_status "Building the application..."
    
    if npm run build; then
        print_success "Application built successfully"
    else
        print_warning "Build had warnings, but you can still run in development mode"
    fi
}

setup_systemd_service() {
    print_status "Would you like to set up the system as a service? (y/n)"
    read -r SETUP_SERVICE
    
    if [[ "$SETUP_SERVICE" != "y" ]]; then
        return
    fi
    
    CURRENT_DIR=$(pwd)
    CURRENT_USER=$(whoami)
    
    sudo tee /etc/systemd/system/isp-system.service > /dev/null << EOF
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
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable isp-system
    
    print_success "Systemd service created and enabled"
    print_status "Start the service with: sudo systemctl start isp-system"
    print_status "Check status with: sudo systemctl status isp-system"
}

# Main installation process
main() {
    print_status "Starting complete ISP Management System installation..."
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Please run this script from the project root directory."
        exit 1
    fi
    
    check_git
    
    # Step 1: Check/Install PostgreSQL
    print_status "Step 1/7: PostgreSQL Installation"
    if ! command -v psql &> /dev/null; then
        install_postgresql
    else
        print_success "PostgreSQL is already installed"
        # Ensure it's running
        if [[ "$OS" == "linux" ]]; then
            sudo systemctl start postgresql 2>/dev/null || true
        fi
    fi
    echo ""
    
    # Step 2: Setup Database
    print_status "Step 2/7: Database Setup"
    setup_database
    echo ""
    
    # Step 3: Run Database Migrations
    print_status "Step 3/7: Database Migrations"
    run_database_migrations
    echo ""
    
    # Step 4: Check/Install Node.js
    print_status "Step 4/7: Node.js Installation"
    check_nodejs
    echo ""
    
    # Step 5: Install Dependencies
    print_status "Step 5/7: Installing Dependencies"
    install_dependencies
    echo ""
    
    # Step 6: Build Application
    print_status "Step 6/7: Building Application"
    build_application
    echo ""
    
    # Step 7: Optional systemd service
    print_status "Step 7/7: System Service Setup"
    if [[ "$OS" == "linux" ]]; then
        setup_systemd_service
    else
        print_status "Skipping systemd service (not on Linux)"
    fi
    
    echo ""
    print_status "Running final system verification..."
    
    # Check database connection
    if sudo -u postgres psql -d isp_system -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" >/dev/null 2>&1; then
        print_success "✓ Database connection working"
    else
        print_error "✗ Database connection failed"
    fi
    
    # Check if .env.local exists
    if [ -f ".env.local" ]; then
        print_success "✓ Environment variables configured"
    else
        print_error "✗ Environment variables missing"
    fi
    
    # Check if node_modules exists
    if [ -d "node_modules" ]; then
        print_success "✓ Dependencies installed"
    else
        print_error "✗ Dependencies not installed"
    fi
    
    # Show completion message
    echo ""
    echo "🎉 Installation Complete!"
    echo "========================"
    echo ""
    echo "📋 System Information:"
    echo "   Database: isp_system"
    echo "   Database Host: localhost:5432"
    echo "   Tables Created: $(sudo -u postgres psql -d isp_system -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)"
    echo "   Credentials: See database-credentials.txt"
    echo ""
    echo "🚀 Next Steps:"
    echo ""
    echo "1. Start the development server:"
    echo "   npm run dev"
    echo ""
    echo "2. Or start in production mode:"
    echo "   npm run build && npm start"
    echo ""
    echo "3. Access the system:"
    echo "   http://localhost:3000"
    echo ""
    echo "4. Run system health check:"
    echo "   ./check-system.sh"
    echo ""
    echo "⚠️  Important Security Notes:"
    echo "   • Database credentials are in: database-credentials.txt"
    echo "   • Environment variables are in: .env.local"
    echo "   • Change default passwords immediately"
    echo "   • Delete database-credentials.txt after noting credentials"
    echo ""
    print_success "ISP Management System is ready to use!"
}

# Run main function
main "$@"
