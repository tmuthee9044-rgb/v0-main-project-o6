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

update_system() {
    print_header "Updating System Packages"
    
    if [[ "$OS" == "linux" ]]; then
        print_info "Updating package lists..."
        
        # Check if apt is locked by another process
        if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            print_warning "Package manager is locked by another process"
            print_info "Waiting for other package operations to complete..."
            
            # Wait up to 2 minutes for lock to be released
            for i in {1..24}; do
                if ! sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
                    break
                fi
                sleep 5
                echo -n "."
            done
            echo ""
            
            if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
                print_error "Package manager is still locked after 2 minutes"
                print_info "Please close other package managers (apt, Software Center, etc.) and try again"
                exit 1
            fi
        fi
        
        # Update package lists
        if sudo apt update; then
            print_success "Package lists updated"
        else
            print_error "Failed to update package lists"
            print_info "This may cause installation issues"
            print_info "Please check your internet connection and try again"
            exit 1
        fi
        
        print_info "Upgrading installed packages (this may take several minutes)..."
        
        # Upgrade packages with automatic yes and non-interactive mode
        if sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"; then
            print_success "System packages upgraded successfully"
        else
            print_warning "Some packages failed to upgrade"
            print_info "This may not affect the ISP system installation"
            print_info "Continuing with installation..."
        fi
        
        # Clean up
        print_info "Cleaning up package cache..."
        sudo apt autoremove -y >/dev/null 2>&1 || true
        sudo apt autoclean -y >/dev/null 2>&1 || true
        
        print_success "System update complete"
        
    elif [[ "$OS" == "macos" ]]; then
        print_info "Updating Homebrew..."
        
        if command -v brew &> /dev/null; then
            brew update
            print_success "Homebrew updated"
            
            print_info "Upgrading Homebrew packages..."
            brew upgrade
            print_success "Homebrew packages upgraded"
        else
            print_warning "Homebrew not installed"
            print_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            print_success "Homebrew installed"
        fi
    fi
}

check_directory_structure() {
    print_header "Checking Directory Structure"
    
    CURRENT_DIR=$(pwd)
    print_info "Current directory: $CURRENT_DIR"
    
    # Count how many times "isp-system" appears in the path
    NEST_COUNT=$(echo "$CURRENT_DIR" | grep -o "isp-system" | wc -l)
    
    if [ "$NEST_COUNT" -gt 2 ]; then
        print_error "Detected deeply nested directory structure!"
        print_error "Path: $CURRENT_DIR"
        print_error "The project directory appears $NEST_COUNT times in the path."
        echo ""
        print_warning "This usually happens when the project is repeatedly cloned/copied into itself."
        echo ""
        print_info "To fix this issue:"
        echo ""
        echo "1. Navigate to your home directory:"
        echo "   cd ~"
        echo ""
        echo "2. Create a fresh directory:"
        echo "   mkdir -p ~/isp-management"
        echo "   cd ~/isp-management"
        echo ""
        echo "3. Clone the project fresh (if using git):"
        echo "   git clone <repository-url> ."
        echo ""
        echo "   OR copy only the necessary files:"
        echo "   cp -r /path/to/original/project/* ."
        echo ""
        echo "4. Run the install script again:"
        echo "   chmod +x install.sh"
        echo "   ./install.sh"
        echo ""
        exit 1
    fi
    
    # Check if we're in the correct project directory
    if [ ! -f "package.json" ]; then
        print_error "package.json not found in current directory"
        print_error "You may be in the wrong directory"
        echo ""
        print_info "Looking for project root..."
        
        # Try to find package.json in parent directories
        SEARCH_DIR="$CURRENT_DIR"
        FOUND=false
        
        for i in {1..5}; do
            SEARCH_DIR=$(dirname "$SEARCH_DIR")
            if [ -f "$SEARCH_DIR/package.json" ]; then
                print_success "Found project root at: $SEARCH_DIR"
                print_info "Please navigate to the project root:"
                echo "   cd $SEARCH_DIR"
                echo "   ./install.sh"
                FOUND=true
                break
            fi
        done
        
        if [ "$FOUND" = false ]; then
            print_error "Could not find project root directory"
            print_info "Please ensure you're in the ISP Management System directory"
        fi
        
        exit 1
    fi
    
    # Check for required files
    MISSING_FILES=()
    
    if [ ! -f "package.json" ]; then
        MISSING_FILES+=("package.json")
    fi
    
    if [ ! -d "app" ]; then
        MISSING_FILES+=("app/ directory")
    fi
    
    if [ ${#MISSING_FILES[@]} -gt 0 ]; then
        print_error "Missing required files/directories:"
        for file in "${MISSING_FILES[@]}"; do
            echo "  - $file"
        done
        echo ""
        print_info "You may be in the wrong directory or the project is incomplete"
        exit 1
    fi
    
    print_success "Directory structure is correct"
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
    
    INSTALLATION_SUCCESS=false
    
    # Method 1: NodeSource Repository (Traditional)
    if [ "$INSTALLATION_SUCCESS" = false ]; then
        print_info "Method 1: Trying NodeSource repository..."
        if [[ "$OS" == "linux" ]]; then
            if curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
               sudo apt update && \
               sudo apt install -y nodejs; then
                
                # Reload environment
                hash -r 2>/dev/null || true
                export PATH="/usr/bin:/usr/local/bin:$PATH"
                sleep 2
                
                if command -v node &> /dev/null; then
                    NODE_VER=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
                    if [ "$NODE_VER" -ge 20 ]; then
                        print_success "NodeSource installation successful: $(node --version)"
                        INSTALLATION_SUCCESS=true
                    fi
                fi
            fi
        elif [[ "$OS" == "macos" ]]; then
            if brew install node@20 && brew link --overwrite --force node@20; then
                hash -r 2>/dev/null || true
                if command -v node &> /dev/null; then
                    print_success "Homebrew installation successful: $(node --version)"
                    INSTALLATION_SUCCESS=true
                fi
            fi
        fi
    fi
    
    # Method 2: NVM (Node Version Manager)
    if [ "$INSTALLATION_SUCCESS" = false ]; then
        print_warning "NodeSource method failed, trying NVM..."
        
        # Install NVM
        if ! command -v nvm &> /dev/null; then
            print_info "Installing NVM..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
            
            # Load NVM
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        fi
        
        # Install Node.js 20 via NVM
        if command -v nvm &> /dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
            [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"
            
            print_info "Installing Node.js 20 via NVM..."
            nvm install 20
            nvm use 20
            nvm alias default 20
            
            # Reload environment
            hash -r 2>/dev/null || true
            sleep 2
            
            if command -v node &> /dev/null; then
                NODE_VER=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
                if [ "$NODE_VER" -ge 20 ]; then
                    print_success "NVM installation successful: $(node --version)"
                    INSTALLATION_SUCCESS=true
                    
                    # Add NVM to shell profiles for persistence
                    for profile in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile"; do
                        if [ -f "$profile" ] && ! grep -q "NVM_DIR" "$profile"; then
                            echo 'export NVM_DIR="$HOME/.nvm"' >> "$profile"
                            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$profile"
                        fi
                    done
                fi
            fi
        fi
    fi
    
    # Method 3: Direct Binary Download (Linux only)
    if [ "$INSTALLATION_SUCCESS" = false ] && [[ "$OS" == "linux" ]]; then
        print_warning "NVM method failed, trying direct binary download..."
        
        NODE_VERSION="20.11.0"
        ARCH=$(uname -m)
        
        if [ "$ARCH" = "x86_64" ]; then
            NODE_ARCH="x64"
        elif [ "$ARCH" = "aarch64" ]; then
            NODE_ARCH="arm64"
        else
            print_warning "Unsupported architecture: $ARCH"
        fi
        
        if [ -n "$NODE_ARCH" ]; then
            print_info "Downloading Node.js v${NODE_VERSION} for ${NODE_ARCH}..."
            
            cd /tmp
            wget "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
            
            if [ -f "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" ]; then
                print_info "Extracting Node.js..."
                sudo mkdir -p /opt/nodejs
                sudo tar -xJf "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -C /opt/nodejs --strip-components=1
                
                # Create symlinks
                sudo ln -sf /opt/nodejs/bin/node /usr/local/bin/node
                sudo ln -sf /opt/nodejs/bin/npm /usr/local/bin/npm
                sudo ln -sf /opt/nodejs/bin/npx /usr/local/bin/npx
                
                # Update PATH
                export PATH="/opt/nodejs/bin:/usr/local/bin:$PATH"
                hash -r 2>/dev/null || true
                
                # Clean up
                rm -f "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
                cd - > /dev/null
                
                sleep 2
                
                if command -v node &> /dev/null; then
                    NODE_VER=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
                    if [ "$NODE_VER" -ge 20 ]; then
                        print_success "Binary installation successful: $(node --version)"
                        INSTALLATION_SUCCESS=true
                        
                        # Add to PATH permanently
                        for profile in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile"; do
                            if [ -f "$profile" ] && ! grep -q "/opt/nodejs/bin" "$profile"; then
                                echo 'export PATH="/opt/nodejs/bin:$PATH"' >> "$profile"
                            fi
                        done
                    fi
                fi
            fi
        fi
    fi
    
    # Method 4: Snap Package (Linux only, last resort)
    if [ "$INSTALLATION_SUCCESS" = false ] && [[ "$OS" == "linux" ]]; then
        if command -v snap &> /dev/null; then
            print_warning "Binary download failed, trying snap package..."
            
            if sudo snap install node --classic --channel=20/stable; then
                hash -r 2>/dev/null || true
                export PATH="/snap/bin:$PATH"
                sleep 2
                
                if command -v node &> /dev/null; then
                    NODE_VER=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
                    if [ "$NODE_VER" -ge 20 ]; then
                        print_success "Snap installation successful: $(node --version)"
                        INSTALLATION_SUCCESS=true
                    fi
                fi
            fi
        fi
    fi
    
    # Check if any method succeeded
    if [ "$INSTALLATION_SUCCESS" = false ]; then
        print_error "All Node.js installation methods failed"
        print_info ""
        print_info "Please try manual installation:"
        echo ""
        echo "Option 1 - Using NVM (Recommended):"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "  source ~/.bashrc"
        echo "  nvm install 20"
        echo "  nvm use 20"
        echo ""
        echo "Option 2 - Using NodeSource:"
        echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "  sudo apt update && sudo apt install -y nodejs"
        echo ""
        echo "After installation, verify with:"
        echo "  node --version  # Should show v20.x.x"
        echo "  npm --version"
        echo ""
        echo "Then run this script again: ./install.sh"
        exit 1
    fi
    
    # Verify npm is available
    if ! command -v npm &> /dev/null; then
        print_error "npm not found after Node.js installation"
        print_info "Attempting to locate npm..."
        
        # Search for npm in common locations
        for npm_location in /usr/bin/npm /usr/local/bin/npm /opt/nodejs/bin/npm "$HOME/.nvm/versions/node/*/bin/npm" /snap/bin/npm; do
            if [ -f "$npm_location" ] || ls $npm_location 2>/dev/null | head -1; then
                NPM_PATH=$(ls $npm_location 2>/dev/null | head -1)
                if [ -n "$NPM_PATH" ]; then
                    print_info "Found npm at: $NPM_PATH"
                    NPM_DIR=$(dirname "$NPM_PATH")
                    export PATH="$NPM_DIR:$PATH"
                    hash -r 2>/dev/null || true
                    break
                fi
            fi
        done
        
        if ! command -v npm &> /dev/null; then
            print_error "npm still not found"
            print_info "Node.js is installed but npm is missing"
            print_info "This is unusual. Please check your Node.js installation."
            exit 1
        fi
    fi
    
    print_success "npm installed: $(npm --version)"
    
    # Verify npm can execute
    if ! npm --version &> /dev/null; then
        print_error "npm is installed but cannot execute"
        print_info "Fixing permissions..."
        sudo chmod +x $(which npm) 2>/dev/null || true
        
        if ! npm --version &> /dev/null; then
            print_error "npm still cannot execute"
            exit 1
        fi
    fi
    
    print_success "Node.js and npm installation complete!"
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
    
    if [ ! -w "." ]; then
        print_error "No write permission in current directory: $(pwd)"
        print_info "Attempting to fix permissions..."
        
        CURRENT_USER=$(whoami)
        CURRENT_DIR=$(pwd)
        
        # Try to fix ownership
        if sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$CURRENT_DIR" 2>/dev/null; then
            print_success "Fixed directory permissions"
        else
            print_error "Cannot fix permissions. Please run:"
            echo "  sudo chown -R $CURRENT_USER:$CURRENT_USER $CURRENT_DIR"
            exit 1
        fi
    fi
    
    if [ ! -d "scripts" ]; then
        print_warning "scripts/ directory not found"
        print_info "Creating scripts directory..."
        mkdir -p scripts
    fi
    
    print_info "Running database migrations..."
    
    DB_NAME="${DB_NAME:-isp_system}"
    DB_USER="${DB_USER:-isp_admin}"
    
    if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        print_error "Database '$DB_NAME' does not exist"
        print_info "Creating database first..."
        setup_database
    fi
    
    MIGRATION_COUNT=0
    for migration_file in scripts/[0-9][0-9][0-9]_*.sql; do
        if [ -f "$migration_file" ]; then
            print_info "Applying migration: $(basename $migration_file)"
            if sudo -u postgres psql -d "$DB_NAME" -f "$migration_file" > /dev/null 2>&1; then
                print_success "Migration applied: $(basename $migration_file)"
                MIGRATION_COUNT=$((MIGRATION_COUNT + 1))
            else
                print_warning "Migration may have already been applied: $(basename $migration_file)"
            fi
        fi
    done
    
    if [ $MIGRATION_COUNT -eq 0 ]; then
        print_warning "No migration files found in scripts/ directory"
        print_info "Database schema may need to be created manually"
    else
        print_success "Applied $MIGRATION_COUNT database migrations"
    fi
}

run_performance_optimizations() {
    print_header "Applying Performance Optimizations"
    
    if [ ! -d "scripts" ]; then
        print_warning "scripts/ directory not found, skipping performance optimizations..."
        return 0
    fi
    
    if [ ! -f "scripts/performance_indexes.sql" ]; then
        print_warning "Performance optimization script not found at: scripts/performance_indexes.sql"
        print_info "Skipping performance optimizations..."
        return 0
    fi
    
    print_info "Creating performance indexes..."
    
    DB_NAME="${DB_NAME:-isp_system}"
    if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        print_error "Database '$DB_NAME' does not exist"
        print_info "Please run full installation first: ./install.sh"
        exit 1
    fi
    
    if sudo -u postgres psql -d "$DB_NAME" -f scripts/performance_indexes.sql; then
        print_success "Performance optimizations applied"
    else
        print_warning "Some performance optimizations may have failed"
        print_info "This is usually not critical and the system will still work"
    fi
}

# ============================================
# INSTALLATION MODES
# ============================================

full_installation() {
    print_header "$SCRIPT_NAME v$VERSION - Full Installation"
    
    check_root
    check_directory_structure  # Added directory structure check
    detect_os
    update_system  # Added system update before installation
    
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
    
    check_directory_structure  # Added directory structure check
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
    
    check_directory_structure  # Added directory structure check
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
    
    check_directory_structure  # Added directory structure check
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
