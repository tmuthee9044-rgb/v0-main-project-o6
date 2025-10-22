#!/bin/bash

# ISP Management System - One-Command Installer
# Downloads and installs everything automatically

set -e

echo "🚀 ISP Management System - Quick Installer"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if we can run commands
print_status "Checking system..."

# Try to install git without sudo first
if ! command -v git &> /dev/null; then
    print_status "Git not found. Attempting to install..."
    
    # Try with apt-get (works on most Debian/Ubuntu systems)
    if command -v apt-get &> /dev/null; then
        print_status "Using apt-get to install git..."
        apt-get update && apt-get install -y git 2>/dev/null || {
            print_error "Cannot install git automatically."
            print_error "Please run as root or with sudo:"
            print_error "  su -"
            print_error "  apt-get update && apt-get install -y git"
            exit 1
        }
    else
        print_error "Cannot install git automatically on this system."
        print_error "Please install git manually and try again."
        exit 1
    fi
fi

print_success "Git is available"

# Download the project
REPO_URL="https://github.com/tmuthee9044-rgb/v0-main-project-o6.git"
PROJECT_DIR="isp-system"

if [ -d "$PROJECT_DIR" ]; then
    print_status "Directory $PROJECT_DIR already exists. Removing..."
    rm -rf "$PROJECT_DIR"
fi

print_status "Downloading ISP Management System..."
git clone "$REPO_URL" "$PROJECT_DIR"

cd "$PROJECT_DIR"

print_success "Project downloaded successfully"

# Make install script executable
chmod +x install.sh

print_status "Starting installation..."
echo ""

# Run the main installer
./install.sh
