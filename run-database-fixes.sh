#!/bin/bash

# Run Database Fixes Script
# This script applies the missing schema elements to fix database errors

set -e

echo "=========================================="
echo "Running Database Schema Fixes"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if PostgreSQL is running
if ! sudo systemctl is-active --quiet postgresql; then
    echo -e "${YELLOW}Starting PostgreSQL service...${NC}"
    sudo systemctl start postgresql
    sleep 2
fi

# Run the fix script
echo -e "${YELLOW}Applying database schema fixes...${NC}"
sudo -u postgres psql -d isp_system -f scripts/fix-missing-schema-elements.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database schema fixes applied successfully${NC}"
    
    # Verify the fixes
    echo ""
    echo -e "${YELLOW}Verifying fixes...${NC}"
    
    # Check if inventory_movements table exists
    TABLE_EXISTS=$(sudo -u postgres psql -d isp_system -tAc "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inventory_movements');")
    
    if [ "$TABLE_EXISTS" = "t" ]; then
        echo -e "${GREEN}✓ inventory_movements table exists${NC}"
    else
        echo -e "${RED}✗ inventory_movements table NOT found${NC}"
    fi
    
    # Check if quantity_received column exists
    COLUMN_EXISTS=$(sudo -u postgres psql -d isp_system -tAc "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'purchase_order_items' AND column_name = 'quantity_received');")
    
    if [ "$COLUMN_EXISTS" = "t" ]; then
        echo -e "${GREEN}✓ purchase_order_items.quantity_received column exists${NC}"
    else
        echo -e "${RED}✗ purchase_order_items.quantity_received column NOT found${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}=========================================="
    echo -e "Database fixes completed successfully!"
    echo -e "==========================================${NC}"
    echo ""
    echo "You can now restart your application:"
    echo "  npm run dev"
    
else
    echo -e "${RED}✗ Failed to apply database schema fixes${NC}"
    exit 1
fi
