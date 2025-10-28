#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}[Pre-Dev Check]${NC} Starting database verification..."

# Check if PostgreSQL is running
if command -v systemctl &> /dev/null; then
    if ! systemctl is-active --quiet postgresql 2>/dev/null; then
        echo -e "${YELLOW}[Warning]${NC} PostgreSQL is not running. Attempting to start..."
        if sudo systemctl start postgresql 2>/dev/null; then
            sleep 2
            echo -e "${GREEN}[Success]${NC} PostgreSQL service started"
        else
            echo -e "${YELLOW}[Warning]${NC} Could not start PostgreSQL automatically"
            echo -e "${YELLOW}[Info]${NC} Run './install.sh' to set up the database"
        fi
    else
        echo -e "${GREEN}[Success]${NC} PostgreSQL service is running"
    fi
elif command -v brew &> /dev/null; then
    # macOS with Homebrew
    if ! brew services list 2>/dev/null | grep postgresql | grep started > /dev/null; then
        echo -e "${YELLOW}[Warning]${NC} PostgreSQL is not running. Attempting to start..."
        brew services start postgresql@15 2>/dev/null || brew services start postgresql 2>/dev/null
        sleep 2
    fi
fi

# Check if .env.local exists
if [ ! -f .env.local ]; then
    echo -e "${YELLOW}[Warning]${NC} .env.local not found. Creating with default values..."
    cat > .env.local << 'EOF'
# Database Configuration (Offline PostgreSQL)
DATABASE_URL=postgresql://isp_admin:isp_password@localhost:5432/isp_system
POSTGRES_URL=postgresql://isp_admin:isp_password@localhost:5432/isp_system
POSTGRES_PRISMA_URL=postgresql://isp_admin:isp_password@localhost:5432/isp_system

# Application Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
EOF
    echo -e "${GREEN}[Success]${NC} Created .env.local with default PostgreSQL configuration"
    echo -e "${YELLOW}[Info]${NC} Run './install.sh' to set up the database with proper credentials"
fi

# Load environment variables
if [ -f .env.local ]; then
    export $(cat .env.local | grep -v '^#' | grep -v '^$' | xargs) 2>/dev/null || true
fi

# Test database connection
if command -v psql &> /dev/null && [ -n "$DATABASE_URL" ]; then
    # Extract database details from DATABASE_URL
    DB_NAME=$(echo "$DATABASE_URL" | sed 's/.*\///' | sed 's/?.*//')
    DB_USER=$(echo "$DATABASE_URL" | sed 's/.*:\/\///' | sed 's/:.*$//')
    DB_HOST=$(echo "$DATABASE_URL" | sed 's/.*@//' | sed 's/:.*//')
    
    if [ "$DB_HOST" = "localhost" ] || [ "$DB_HOST" = "127.0.0.1" ]; then
        # Only test local PostgreSQL connections
        if PGPASSWORD="${DATABASE_URL#*:}" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null 2>&1; then
            echo -e "${GREEN}[Success]${NC} Database connection verified"
            
            # Check if tables exist
            TABLE_COUNT=$(PGPASSWORD="${DATABASE_URL#*:}" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs || echo "0")
            
            if [ "$TABLE_COUNT" -ge 12 ]; then
                echo -e "${GREEN}[Success]${NC} Found $TABLE_COUNT tables in database"
            elif [ "$TABLE_COUNT" -gt 0 ]; then
                echo -e "${YELLOW}[Warning]${NC} Only $TABLE_COUNT tables found. Expected at least 12."
                echo -e "${YELLOW}[Info]${NC} Run './install.sh' to create missing tables"
            else
                echo -e "${YELLOW}[Warning]${NC} No tables found in database"
                echo -e "${YELLOW}[Info]${NC} Run './install.sh' to set up the database schema"
            fi
        else
            echo -e "${YELLOW}[Warning]${NC} Could not connect to local database"
            echo -e "${YELLOW}[Info]${NC} Run './install.sh' to set up the database"
        fi
    else
        echo -e "${GREEN}[Info]${NC} Using cloud database (Neon)"
    fi
else
    if [ -z "$DATABASE_URL" ]; then
        echo -e "${YELLOW}[Warning]${NC} DATABASE_URL not configured"
        echo -e "${YELLOW}[Info]${NC} Run './install.sh' to set up the database"
    fi
fi

echo -e "${GREEN}[Pre-Dev Check]${NC} Complete. Starting Next.js dev server..."
echo ""
