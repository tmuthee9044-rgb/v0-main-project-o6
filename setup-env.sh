#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                    ISP SYSTEM - Environment Setup                           "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find project root
PROJECT_ROOT=$(pwd)
if [ ! -f "$PROJECT_ROOT/package.json" ]; then
    echo -e "${YELLOW}⚠ Not in project root. Searching...${NC}"
    PROJECT_ROOT=$(find ~ -name "package.json" -path "*/isp-system*/package.json" 2>/dev/null | head -1 | xargs dirname)
    if [ -z "$PROJECT_ROOT" ]; then
        echo -e "${RED}✗ Could not find project root${NC}"
        exit 1
    fi
    cd "$PROJECT_ROOT"
fi

echo -e "${GREEN}✓ Project root: $PROJECT_ROOT${NC}"

# Create .env.local with Neon database connection
echo -e "\n${YELLOW}▶ Creating .env.local file...${NC}"

cat > .env.local << 'EOF'
# Neon Database Configuration (Cloud - Online)
DATABASE_URL="postgres://neondb_owner:npg_v9gKOZ2wLESB@ep-wispy-violet-admwxtkv-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require"
POSTGRES_URL="postgres://neondb_owner:npg_v9gKOZ2wLESB@ep-wispy-violet-admwxtkv-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require"
POSTGRES_PRISMA_URL="postgres://neondb_owner:npg_v9gKOZ2wLESB@ep-wispy-violet-admwxtkv-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require"
DATABASE_URL_UNPOOLED="postgres://neondb_owner:npg_v9gKOZ2wLESB@ep-wispy-violet-admwxtkv-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require"

# Next.js Configuration
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NODE_ENV="development"
EOF

echo -e "${GREEN}✓ .env.local created with Neon database connection${NC}"

# Display the configuration
echo -e "\n${YELLOW}━━━ Environment Configuration ━━━${NC}"
echo "Database: Neon Cloud (Online)"
echo "Connection: ep-wispy-violet-admwxtkv-pooler.c-2.us-east-1.aws.neon.tech"
echo "App URL: http://localhost:3000"

echo -e "\n${GREEN}✓ Environment setup complete!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Restart your dev server: npm run dev"
echo "2. The app will now connect to the Neon cloud database"
echo ""
</EOF>

chmod +x setup-env.sh
