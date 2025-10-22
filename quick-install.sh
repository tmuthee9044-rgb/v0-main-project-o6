#!/bin/bash

# ISP Management System - Quick Installer
# This script downloads and installs everything automatically

set -e

echo "=========================================="
echo "ISP Management System - Quick Installer"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run this script as root${NC}"
   echo "Run as a regular user. The script will ask for sudo password when needed."
   exit 1
fi

echo "Step 1: Downloading project from GitHub..."
echo ""

# Check if wget or curl is available
if command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget -O isp-system.zip"
elif command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl -L -o isp-system.zip"
else
    echo -e "${RED}Error: Neither wget nor curl is installed${NC}"
    echo "Please install one of them first:"
    echo "  apt install wget"
    echo "  or"
    echo "  apt install curl"
    exit 1
fi

# Download the ZIP file
$DOWNLOAD_CMD https://github.com/tmuthee9044-rgb/v0-main-project-o6/archive/refs/heads/main.zip

if [ ! -f "isp-system.zip" ]; then
    echo -e "${RED}Failed to download project${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Downloaded successfully${NC}"
echo ""

echo "Step 2: Extracting files..."
echo ""

# Check if unzip is installed
if ! command -v unzip &> /dev/null; then
    echo "Installing unzip..."
    sudo apt update && sudo apt install -y unzip
fi

# Extract the ZIP file
unzip -q isp-system.zip

# Remove the ZIP file
rm isp-system.zip

# Rename the extracted folder
if [ -d "v0-main-project-o6-main" ]; then
    mv v0-main-project-o6-main isp-system
elif [ -d "v0-main-project-o6-master" ]; then
    mv v0-main-project-o6-master isp-system
fi

if [ ! -d "isp-system" ]; then
    echo -e "${RED}Failed to extract project${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Extracted successfully${NC}"
echo ""

echo "Step 3: Running installation script..."
echo ""

# Change to project directory
cd isp-system

# Make install script executable
chmod +x install.sh

# Run the installation script
./install.sh

echo ""
echo "=========================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "To start the system:"
echo "  cd isp-system"
echo "  npm run dev"
echo ""
echo "Then open: http://localhost:3000"
echo ""
