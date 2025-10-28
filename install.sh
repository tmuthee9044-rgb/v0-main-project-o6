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
    else
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
    fi
    
    if [[ "$OS" == "linux" ]]; then
        print_info "Installing PostgreSQL development libraries and build tools..."
        sudo apt install -y \
            libpq-dev \
            build-essential \
            python3 \
            python3-pip \
            make \
            g++ \
            gcc
        print_success "Build tools installed"
    elif [[ "$OS" == "macos" ]]; then
        print_info "Installing build tools..."
        xcode-select --install 2>/dev/null || true
        print_success "Build tools installed"
    fi
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
        CURRENT_NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$CURRENT_NODE_VERSION" -lt 20 ]; then
            print_warning "Found old Node.js version $(node --version), removing completely..."
            
            if [[ "$OS" == "linux" ]]; then
                # Remove all Node.js related packages
                sudo apt remove -y nodejs npm node 2>/dev/null || true
                sudo apt purge -y nodejs npm node 2>/dev/null || true
                sudo apt autoremove -y
                
                # Remove old NodeSource repositories
                sudo rm -f /etc/apt/sources.list.d/nodesource.list
                sudo rm -f /etc/apt/sources.list.d/nodesource.list.save
                
                # Remove any remaining Node.js files
                sudo rm -rf /usr/local/bin/node /usr/local/bin/npm
                sudo rm -rf /usr/local/lib/node_modules
                sudo rm -rf /usr/local/include/node
                sudo rm -rf /opt/nodejs
                
                # Clear apt cache
                sudo apt clean
                sudo apt update
                
            elif [[ "$OS" == "macos" ]]; then
                brew uninstall node 2>/dev/null || true
                brew uninstall node@* 2>/dev/null || true
                brew cleanup
            fi
            
            # Clear shell hash table
            hash -r 2>/dev/null || true
            
            print_success "Old Node.js removed completely"
        else
            print_success "Node.js already installed: $(node --version)"
            
            # Check if npm exists
            if command -v npm &> /dev/null; then
                print_success "npm already installed: $(npm --version)"
                return 0
            fi
        fi
    fi
    
    print_info "Installing Node.js 20.x with npm..."
    
    MAX_RETRIES=3
    RETRY_COUNT=0
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if [[ "$OS" == "linux" ]]; then
            # Clean install of NodeSource repository
            print_info "Setting up NodeSource repository..."
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            
            # Update package list
            sudo apt update
            
            # Install Node.js (includes npm)
            print_info "Installing nodejs package..."
            sudo apt install -y nodejs
            
        elif [[ "$OS" == "macos" ]]; then
            brew install node@20
            brew link --overwrite --force node@20
        fi
        
        # Reload environment
        print_info "Reloading environment..."
        hash -r 2>/dev/null || true
        export PATH="/usr/bin:/usr/local/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.npm-global/bin:$PATH"
        
        # Source profile files
        [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
        [ -f "$HOME/.profile" ] && source "$HOME/.profile" 2>/dev/null || true
        [ -f "$HOME/.bash_profile" ] && source "$HOME/.bash_profile" 2>/dev/null || true
        
        # Wait for system to update
        sleep 3
        
        # Verify Node.js installation
        if ! command -v node &> /dev/null; then
            print_warning "Node.js command not found, retrying... (Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
            RETRY_COUNT=$((RETRY_COUNT + 1))
            sleep 2
            continue
        fi
        
        INSTALLED_NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$INSTALLED_NODE_VERSION" -lt 20 ]; then
            print_warning "Wrong Node.js version installed: $(node --version)"
            print_warning "Expected: v20.x or higher"
            print_info "Removing and retrying... (Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
            
            # Remove the wrong version
            if [[ "$OS" == "linux" ]]; then
                sudo apt remove -y nodejs npm 2>/dev/null || true
                sudo apt purge -y nodejs npm 2>/dev/null || true
                sudo apt autoremove -y
                sudo rm -f /etc/apt/sources.list.d/nodesource.list
                sudo apt clean
                sudo apt update
            fi
            
            RETRY_COUNT=$((RETRY_COUNT + 1))
            sleep 2
            continue
        fi
        
        # Success!
        print_success "Node.js installed: $(node --version)"
        break
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        print_error "Failed to install Node.js 20.x after $MAX_RETRIES attempts"
        print_info ""
        print_info "Manual installation steps:"
        echo "  1. Remove all Node.js versions:"
        echo "     sudo apt remove -y nodejs npm"
        echo "     sudo apt purge -y nodejs npm"
        echo "     sudo apt autoremove -y"
        echo ""
        echo "  2. Install Node.js 20.x:"
        echo "     curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "     sudo apt update"
        echo "     sudo apt install -y nodejs"
        echo ""
        echo "  3. Verify installation:"
        echo "     node --version  # Should show v20.x.x"
        echo "     npm --version"
        echo ""
        echo "  4. Run this script again"
        exit 1
    fi
    
    # Verify npm is available
    if ! command -v npm &> /dev/null; then
        print_error "npm not found after Node.js installation"
        print_info "Attempting to locate npm..."
        
        # Search for npm in common locations
        for npm_location in /usr/bin/npm /usr/local/bin/npm /opt/nodejs/bin/npm; do
            if [ -f "$npm_location" ]; then
                print_info "Found npm at: $npm_location"
                NPM_DIR=$(dirname "$npm_location")
                export PATH="$NPM_DIR:$PATH"
                hash -r 2>/dev/null || true
                break
            fi
        done
        
        if ! command -v npm &> /dev/null; then
            print_error "npm installation failed"
            print_info "Installing npm separately..."
            
            if [[ "$OS" == "linux" ]]; then
                sudo apt install -y npm
            elif [[ "$OS" == "macos" ]]; then
                brew reinstall node@20
            fi
            
            # Final check
            if ! command -v npm &> /dev/null; then
                print_error "Could not install npm"
                print_info "Please install npm manually and run this script again"
                exit 1
            fi
        fi
    fi
    
    print_success "npm installed: $(npm --version)"
    
    # Verify npm can execute
    if ! npm --version &> /dev/null; then
        print_error "npm is installed but cannot execute"
        print_info "Fixing permissions..."
        sudo chmod +x $(which npm)
        
        if ! npm --version &> /dev/null; then
            print_error "npm still cannot execute"
            exit 1
        fi
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
    
    install_nodejs
    install_dependencies
    
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
    install_dependencies
    
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
