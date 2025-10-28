#!/bin/bash

# ISP Management System - Unified Installation Script
# This script handles all installation scenarios in one place

set -e

# ============================================
# CONFIGURATION
# ============================================

VERSION="1.0.0"
SCRIPT_NAME="ISP Management System Installer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================
# UTILITY FUNCTIONS
# ============================================

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this script as root. Run as a regular user."
        print_info "The script will ask for sudo password when needed."
        exit 1
    fi
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        print_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    print_info "Detected OS: $OS"
}

# ============================================
# INSTALLATION FUNCTIONS
# ============================================

install_postgresql() {
    print_header "Installing PostgreSQL"
    
    if command -v psql &> /dev/null; then
        print_success "PostgreSQL already installed: $(psql --version | head -n1)"
        return 0
    fi
    
    print_info "Installing PostgreSQL..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    elif [[ "$OS" == "macos" ]]; then
        brew install postgresql@15
        brew services start postgresql@15
    fi
    
    print_success "PostgreSQL installed"
}

setup_database() {
    print_header "Setting Up Database"
    
    DB_NAME="${DB_NAME:-isp_system}"
    DB_USER="${DB_USER:-isp_admin}"
    DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)}"
    
    print_info "Creating database: $DB_NAME"
    print_info "Creating user: $DB_USER"
    
    # Create user and database
    sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" 2>/dev/null || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" 2>/dev/null || true
    
    print_success "Database created successfully"
    
    # Create environment file
    print_info "Creating .env.local file..."
    cat > .env.local << 'ENVEOF'
DATABASE_URL=postgresql://DB_USER_PLACEHOLDER:DB_PASSWORD_PLACEHOLDER@localhost:5432/DB_NAME_PLACEHOLDER
POSTGRES_URL=postgresql://DB_USER_PLACEHOLDER:DB_PASSWORD_PLACEHOLDER@localhost:5432/DB_NAME_PLACEHOLDER
POSTGRES_PRISMA_URL=postgresql://DB_USER_PLACEHOLDER:DB_PASSWORD_PLACEHOLDER@localhost:5432/DB_NAME_PLACEHOLDER
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
ENVEOF

    # Replace placeholders
    sed -i.bak "s/DB_USER_PLACEHOLDER/${DB_USER}/g" .env.local
    sed -i.bak "s/DB_PASSWORD_PLACEHOLDER/${DB_PASSWORD}/g" .env.local
    sed -i.bak "s/DB_NAME_PLACEHOLDER/${DB_NAME}/g" .env.local
    rm -f .env.local.bak
    
    print_success "Environment file created"
    
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
}

install_nodejs() {
    print_header "Installing Node.js"
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js already installed: $NODE_VERSION"
        
        # Check if npm exists
        if command -v npm &> /dev/null; then
            print_success "npm already installed: $(npm --version)"
            return 0
        fi
    fi
    
    print_info "Installing Node.js 20.x with npm..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt update
        sudo apt install -y nodejs npm
        
        if ! dpkg -l | grep -q nodejs; then
            print_error "Node.js package installation failed"
            exit 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        brew install node@20
        brew link --overwrite node@20
    fi
    
    print_info "Reloading environment..."
    
    # Update PATH with common Node.js installation locations
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.npm-global/bin:$PATH"
    
    # Reload bash hash table
    hash -r 2>/dev/null || true
    
    # Source profile files to get updated PATH
    [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
    [ -f "$HOME/.profile" ] && source "$HOME/.profile" 2>/dev/null || true
    [ -f "$HOME/.bash_profile" ] && source "$HOME/.bash_profile" 2>/dev/null || true
    
    # Wait a moment for system to update
    sleep 2
    
    # Verify Node.js installation
    if ! command -v node &> /dev/null; then
        print_error "Node.js installation failed"
        print_info "Please install manually from https://nodejs.org/"
        exit 1
    fi
    
    print_success "Node.js installed: $(node --version)"
    
    if ! command -v npm &> /dev/null; then
        print_warning "npm not found in PATH, attempting recovery..."
        
        # Try to find npm binary in common locations
        for npm_location in /usr/bin/npm /usr/local/bin/npm /opt/nodejs/bin/npm; do
            if [ -f "$npm_location" ]; then
                print_info "Found npm at: $npm_location"
                NPM_DIR=$(dirname "$npm_location")
                export PATH="$NPM_DIR:$PATH"
                hash -r 2>/dev/null || true
                break
            fi
        done
        
        # If still not found, search the entire system
        if ! command -v npm &> /dev/null; then
            print_info "Searching system for npm..."
            NPM_PATH=$(find /usr /opt -name npm -type f 2>/dev/null | head -n1)
            
            if [ -n "$NPM_PATH" ]; then
                print_info "Found npm at: $NPM_PATH"
                NPM_DIR=$(dirname "$NPM_PATH")
                export PATH="$NPM_DIR:$PATH"
                hash -r 2>/dev/null || true
            fi
        fi
        
        if ! command -v npm &> /dev/null; then
            print_warning "Installing npm separately..."
            
            if [[ "$OS" == "linux" ]]; then
                # Try apt first
                sudo apt update
                sudo apt install -y npm || {
                    print_warning "apt install failed, trying alternative method..."
                    # Try installing from npm's official installer
                    curl -L https://www.npmjs.com/install.sh | sudo sh
                }
            elif [[ "$OS" == "macos" ]]; then
                brew reinstall node@20
            fi
            
            # Update PATH and reload
            export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
            hash -r 2>/dev/null || true
            sleep 2
        fi
    fi
    
    if ! command -v npm &> /dev/null; then
        print_error "npm installation failed after multiple attempts"
        echo ""
        print_info "Troubleshooting steps:"
        echo "  1. Check if npm is installed:"
        echo "     dpkg -l | grep npm"
        echo ""
        echo "  2. Try to find npm manually:"
        echo "     sudo find / -name npm 2>/dev/null"
        echo ""
        echo "  3. If found, add to PATH:"
        echo "     export PATH=\"/path/to/npm:\$PATH\""
        echo ""
        echo "  4. Or reinstall Node.js manually:"
        echo "     curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -"
        echo "     sudo apt install -y nodejs npm"
        echo ""
        echo "  5. Then run this script again"
        echo ""
        exit 1
    fi
    
    print_success "npm installed: $(npm --version)"
    
    if ! npm --version &> /dev/null; then
        print_error "npm is installed but cannot execute"
        print_info "Try running: sudo chmod +x $(which npm)"
        exit 1
    fi
}

install_dependencies() {
    print_header "Installing Project Dependencies"
    
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Are you in the project directory?"
        exit 1
    fi
    
    print_info "Cleaning previous installations..."
    rm -rf node_modules package-lock.json .next
    npm cache clean --force
    
    print_info "Installing npm packages (this may take several minutes)..."
    npm install --legacy-peer-deps
    
    print_success "Dependencies installed"
}

build_application() {
    print_header "Building Application"
    
    print_info "Building Next.js application..."
    npm run build
    
    print_success "Build complete"
}

apply_database_fixes() {
    print_header "Applying Database Schema Fixes"
    
    if [ ! -f "scripts/fix-missing-schema-elements.sql" ]; then
        print_warning "Database fix script not found, skipping..."
        return 0
    fi
    
    print_info "Applying schema fixes..."
    sudo -u postgres psql -d "${DB_NAME:-isp_system}" -f scripts/fix-missing-schema-elements.sql
    
    print_success "Database schema fixes applied"
}

run_performance_optimizations() {
    print_header "Applying Performance Optimizations"
    
    if [ ! -f "scripts/performance_indexes.sql" ]; then
        print_warning "Performance optimization script not found, skipping..."
        return 0
    fi
    
    print_info "Creating performance indexes..."
    sudo -u postgres psql -d "${DB_NAME:-isp_system}" -f scripts/performance_indexes.sql
    
    print_success "Performance optimizations applied"
}

# ============================================
# INSTALLATION MODES
# ============================================

full_installation() {
    print_header "$SCRIPT_NAME v$VERSION - Full Installation"
    
    check_root
    detect_os
    
    install_postgresql
    setup_database
    install_nodejs
    install_dependencies
    apply_database_fixes
    run_performance_optimizations
    build_application
    
    print_header "Installation Complete!"
    echo ""
    print_success "ISP Management System has been installed successfully!"
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
}

quick_fix_npm() {
    print_header "$SCRIPT_NAME - NPM Dependency Fix"
    
    fix_npm_dependencies
    
    print_header "NPM Fix Complete!"
    echo ""
    print_success "Dependencies have been reinstalled"
    echo ""
    echo "You can now run:"
    echo "  npm run dev"
    echo ""
}

quick_fix_database() {
    print_header "$SCRIPT_NAME - Database Fix"
    
    detect_os
    apply_database_fixes
    run_performance_optimizations
    
    print_header "Database Fix Complete!"
    echo ""
    print_success "Database schema has been updated"
    echo ""
    echo "You can now restart your application:"
    echo "  npm run dev"
    echo ""
}

reinstall_dependencies() {
    print_header "$SCRIPT_NAME - Reinstall Dependencies"
    
    install_nodejs
    fix_npm_dependencies
    
    print_header "Reinstall Complete!"
    echo ""
    print_success "Node.js and dependencies have been reinstalled"
    echo ""
}

show_usage() {
    cat << EOF
$SCRIPT_NAME v$VERSION

Usage: ./install.sh [OPTION]

Options:
  (no option)    Full installation (default)
  --fix-npm      Fix npm dependency issues only
  --fix-db       Apply database schema fixes only
  --reinstall    Reinstall Node.js and dependencies
  --help         Show this help message

Examples:
  ./install.sh                 # Full installation
  ./install.sh --fix-npm       # Fix npm issues
  ./install.sh --fix-db        # Fix database schema
  ./install.sh --reinstall     # Reinstall dependencies

EOF
}

# ============================================
# MAIN EXECUTION
# ============================================

main() {
    case "${1:-}" in
        --fix-npm)
            quick_fix_npm
            ;;
        --fix-db)
            quick_fix_database
            ;;
        --reinstall)
            reinstall_dependencies
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            full_installation
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
