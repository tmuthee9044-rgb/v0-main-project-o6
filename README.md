# ISP Management System

A comprehensive Internet Service Provider (ISP) management system built with Next.js 15, PostgreSQL, and modern web technologies. Designed for offline-first operation with optional cloud database support.

## 🚀 Quick Start

### Prerequisites
- **Operating System**: Linux (Ubuntu/Debian recommended) or macOS
- **Node.js**: v20.x or higher
- **PostgreSQL**: v14 or higher
- **RAM**: At least 4GB
- **Disk Space**: At least 10GB free

### One-Command Installation

\`\`\`bash
# Clone or download the project
cd isp-management-system

# Run the automated installation script
chmod +x install.sh
./install.sh
\`\`\`

The installation script will automatically:
- ✅ Update your system packages
- ✅ Install Node.js v20.x (tries 4 different methods)
- ✅ Install PostgreSQL database server
- ✅ Install npm dependencies (tries 3 different methods)
- ✅ Create database and user with proper permissions
- ✅ Run all database migrations (12 core tables + indexes)
- ✅ Verify database connection and table creation
- ✅ Test database operations (CRUD)
- ✅ Create .env.local with correct credentials
- ✅ Build and start the application

**Installation time**: 10-15 minutes (depending on internet speed)

### Manual Installation

If the automated script fails, you can install manually:

\`\`\`bash
# 1. Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Install PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# 3. Create database and user
sudo -u postgres psql << EOF
CREATE USER isp_admin WITH PASSWORD 'isp_password';
CREATE DATABASE isp_system OWNER isp_admin;
GRANT ALL PRIVILEGES ON DATABASE isp_system TO isp_admin;
\q
EOF

# 4. Create .env.local file
cat > .env.local << 'EOF'
DATABASE_URL=postgresql://isp_admin:isp_password@localhost:5432/isp_system
POSTGRES_URL=postgresql://isp_admin:isp_password@localhost:5432/isp_system
POSTGRES_PRISMA_URL=postgresql://isp_admin:isp_password@localhost:5432/isp_system
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
EOF

# 5. Install dependencies and run migrations
npm install
npm run build

# 6. Start the application
npm run dev
\`\`\`

## 🌐 Access Your System

After installation completes, access the system at:

**Web Interface**: http://localhost:3000

### Default Credentials

**Database**:
- Host: `localhost`
- Port: `5432`
- Database: `isp_system`
- Username: `isp_admin`
- Password: `isp_password`

**Admin Panel**: Create your admin account on first visit

## 📊 System Architecture

### Technology Stack
- **Frontend**: Next.js 15 (App Router), React 18, TypeScript
- **Backend**: Next.js API Routes, Server Actions
- **Database**: PostgreSQL 14+ (offline) or Neon (cloud)
- **Styling**: Tailwind CSS v4, shadcn/ui components
- **State Management**: React Server Components, SWR
- **Authentication**: NextAuth.js (optional)

### Database Schema (12 Core Tables)

1. **customers** - Customer information and account details
2. **service_plans** - Internet service plans and pricing
3. **customer_services** - Active customer subscriptions
4. **payments** - Payment records and M-Pesa transactions
5. **invoices** - Billing and invoice management
6. **network_devices** - Network equipment and infrastructure
7. **ip_addresses** - IP address allocation and management
8. **employees** - Staff information and HR data
9. **payroll** - Employee payroll and salary records
10. **leave_requests** - Employee leave management
11. **activity_logs** - System audit trail and logging
12. **schema_migrations** - Database migration tracking

## 🛠️ Development

### Start Development Server

\`\`\`bash
npm run dev
\`\`\`

The pre-dev check script automatically:
- Verifies PostgreSQL is running
- Checks database connection
- Validates all 12 tables exist
- Creates missing database/tables if needed

### Build for Production

\`\`\`bash
npm run build
npm start
\`\`\`

### Database Management

#### View Database in Browser
Navigate to: http://localhost:3000/admin/database-browser

Features:
- Browse all tables with pagination
- View table schemas and relationships
- Execute SQL queries (SELECT, INSERT, UPDATE, DELETE)
- Export data
- Real-time query execution

#### Sync Database Schema
Navigate to: http://localhost:3000/settings (Database tab)

Click "Sync Database Schema" to:
- Check database connection
- Verify all tables exist
- Run pending migrations
- Repair schema issues automatically

#### Command Line Database Access

\`\`\`bash
# Connect to database
psql -h localhost -U isp_admin -d isp_system

# Run migrations manually
sudo -u postgres psql -d isp_system -f scripts/000_complete_schema.sql

# Check table list
psql -h localhost -U isp_admin -d isp_system -c "\dt"

# Backup database
pg_dump -h localhost -U isp_admin isp_system > backup.sql

# Restore database
psql -h localhost -U isp_admin -d isp_system < backup.sql
\`\`\`

## 📋 Features

### Customer Management
- Customer registration and profiles
- Service plan assignment
- Connection quality monitoring
- Customer portal access

### Billing & Payments
- Automated invoice generation
- M-Pesa payment integration
- Payment tracking and reconciliation
- Balance management

### Network Management
- Device inventory and monitoring
- IP address allocation
- Network topology visualization
- Performance monitoring

### Support System
- Ticket management
- Customer communication
- Issue tracking and resolution
- SLA monitoring

### HR Management
- Employee records
- Payroll processing
- Leave management
- Attendance tracking

### Reports & Analytics
- Financial reports
- Customer analytics
- Network performance reports
- Custom report generation

### System Administration
- User management
- Role-based access control
- System configuration
- Audit logging

## 🔧 Configuration

### Environment Variables

Edit `.env.local` to configure:

\`\`\`bash
# Database (Local PostgreSQL)
DATABASE_URL=postgresql://isp_admin:isp_password@localhost:5432/isp_system

# Database (Cloud - Neon)
# DATABASE_URL=postgresql://user:password@ep-xxx.neon.tech/dbname?sslmode=require

# Application
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development

# Security (Change in production!)
NEXTAUTH_SECRET=your-secret-key-change-in-production
NEXTAUTH_URL=http://localhost:3000
\`\`\`

### Switching Between Local and Cloud Database

The system automatically detects which database to use based on `DATABASE_URL`:

**Local PostgreSQL** (offline):
\`\`\`bash
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
\`\`\`

**Neon Cloud** (online):
\`\`\`bash
DATABASE_URL=postgresql://user:password@ep-xxx.neon.tech/dbname?sslmode=require
\`\`\`

The `neon-wrapper` library handles both seamlessly.

## 🔒 Security

### Production Deployment Checklist

- [ ] Change default database password
- [ ] Set strong `NEXTAUTH_SECRET`
- [ ] Enable HTTPS/SSL
- [ ] Configure firewall (allow only ports 80, 443, 22)
- [ ] Set up regular database backups
- [ ] Enable PostgreSQL SSL connections
- [ ] Implement rate limiting
- [ ] Set up monitoring and alerts
- [ ] Review and restrict database user permissions
- [ ] Enable audit logging

### Database Security

\`\`\`sql
-- Create read-only user for reports
CREATE USER report_user WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE isp_system TO report_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_user;

-- Revoke unnecessary permissions
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
\`\`\`

## 🆘 Troubleshooting

### Common Issues

#### 1. "Could not connect to local database"

**Cause**: PostgreSQL not running or wrong credentials

**Solution**:
\`\`\`bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Start PostgreSQL
sudo systemctl start postgresql

# Verify credentials in .env.local
cat .env.local

# Test connection
psql -h localhost -U isp_admin -d isp_system
\`\`\`

#### 2. "Permission denied" errors during installation

**Cause**: Directory permission issues

**Solution**:
\`\`\`bash
# Fix directory permissions
sudo chown -R $USER:$USER ~/isp-system
chmod -R 755 ~/isp-system

# Run installation again
./install.sh
\`\`\`

#### 3. "React version mismatch" error

**Cause**: Conflicting React versions in node_modules

**Solution**:
\`\`\`bash
# Clean install
rm -rf node_modules package-lock.json
npm install
\`\`\`

#### 4. "Port 3000 already in use"

**Cause**: Another process using port 3000

**Solution**:
\`\`\`bash
# Find and kill process
sudo lsof -i :3000
kill -9 <PID>

# Or use different port
PORT=3001 npm run dev
\`\`\`

#### 5. Missing database tables

**Cause**: Migrations not run

**Solution**:
\`\`\`bash
# Run migrations manually
./install.sh --fix-db

# Or via web interface
# Navigate to http://localhost:3000/settings
# Click "Sync Database Schema" button
\`\`\`

#### 6. "ECONNREFUSED 127.0.0.1:443" error

**Cause**: System trying to connect to cloud database instead of local

**Solution**:
\`\`\`bash
# Check .env.local
cat .env.local

# Ensure DATABASE_URL points to localhost
# Should be: postgresql://isp_admin:isp_password@localhost:5432/isp_system
# NOT: postgresql://...@ep-xxx.neon.tech/...

# Update .env.local if needed
nano .env.local

# Restart dev server
npm run dev
\`\`\`

### Getting Help

1. **Check logs**: Look for error messages in terminal
2. **Database logs**: `sudo tail -f /var/log/postgresql/postgresql-*.log`
3. **Application logs**: Check `./logs` directory
4. **Run diagnostics**: `./install.sh --verify`

## 📈 Performance Optimization

### Database Optimization

The system includes 18 performance indexes on:
- Customer lookups (email, phone, status)
- Payment queries (customer_id, date, status)
- Invoice searches (customer_id, status, date)
- Network device monitoring (status, type, IP)
- Employee queries (employee_id, department, status)

### Application Performance

- Server-side rendering for fast initial load
- Incremental Static Regeneration for reports
- SWR for client-side data caching
- Optimized database queries with indexes
- Connection pooling for database

## 🔄 Updates and Maintenance

### Updating the System

\`\`\`bash
# Pull latest changes
git pull origin main

# Install new dependencies
npm install

# Run new migrations
npm run dev  # Migrations run automatically

# Or manually
./install.sh --fix-db
\`\`\`

### Database Migrations

Add new migrations to `scripts/` directory:

\`\`\`bash
# Create new migration
touch scripts/002_add_new_feature.sql

# Migration will run automatically on next start
npm run dev
\`\`\`

### Backup Strategy

\`\`\`bash
# Daily backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump -h localhost -U isp_admin isp_system > backups/backup_$DATE.sql

# Add to crontab for daily backups at 2 AM
0 2 * * * /path/to/backup-script.sh
\`\`\`

## 📝 License

Proprietary - All rights reserved

## 🤝 Support

For technical support or questions:
- Check the troubleshooting section above
- Review application logs in `./logs` directory
- Check database logs: `/var/log/postgresql/`
- Run system diagnostics: `./install.sh --verify`

---

**System Status**: Production Ready  
**Version**: 1.0.0  
**Last Updated**: 2025
