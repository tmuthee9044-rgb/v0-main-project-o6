# ISP Management System - Complete Installation Guide

## One-Command Installation (Recommended)

Run this single command to install everything including all prerequisites:

\`\`\`bash
chmod +x install.sh && ./install.sh
\`\`\`

That's it! The script will automatically:
- ✅ Install PostgreSQL database server
- ✅ Create database and user with secure credentials
- ✅ Run all 150+ SQL migration scripts to create tables
- ✅ Install Node.js 20+ (required for database compatibility)
- ✅ Install all project dependencies
- ✅ Build the application
- ✅ Configure environment variables
- ✅ Optionally set up systemd service for auto-start

## What Happens During Installation

The installation script performs these steps:

1. **System Detection:** Identifies your OS (Ubuntu, Debian, macOS)
2. **PostgreSQL Installation:** Installs and configures PostgreSQL
3. **Database Setup:** Creates `isp_system` database with secure credentials
4. **Schema Migration:** Runs all SQL scripts to create tables and relationships
5. **Node.js Setup:** Installs Node.js 20+ if needed
6. **Dependencies:** Installs all npm packages
7. **Build:** Compiles the application for production
8. **Configuration:** Generates `.env.local` with database credentials

## After Installation

Once installation completes, you'll find:

1. **Database Credentials:** Saved in `database-credentials.txt`
   - Database: `isp_system`
   - User: `isp_admin`
   - Password: (auto-generated secure password)
   - ⚠️ Keep this file secure!

2. **Environment Variables:** Saved in `.env.local`
   - Database connection strings
   - JWT secrets
   - Application configuration

3. **Ready to Run:**
   \`\`\`bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   \`\`\`

4. **Access the System:**
   - Open: `http://localhost:3000`
   - Create your admin account
   - Start managing your ISP operations

## Offline Capability

The system is fully configured for offline use:
- ✅ Local PostgreSQL database
- ✅ All dependencies installed locally
- ✅ No external API dependencies required
- ✅ Works without internet connection

## System Requirements

- **OS:** Ubuntu 20.04+, Debian 11+, macOS 10.15+
- **RAM:** 2GB minimum, 4GB recommended
- **Disk:** 2GB for application + database
- **Sudo Access:** Required for installing PostgreSQL

## Optional: Systemd Service (Linux)

The installer can optionally set up a systemd service for auto-start:

\`\`\`bash
# Start the service
sudo systemctl start isp-system

# Check status
sudo systemctl status isp-system

# View logs
sudo journalctl -u isp-system -f
\`\`\`

## Troubleshooting

**Permission denied error:**
\`\`\`bash
chmod +x install.sh
\`\`\`

**PostgreSQL already installed:**
The script will detect existing PostgreSQL and skip installation.

**Database already exists:**
The script will drop and recreate the database (data will be lost).

**Port 3000 already in use:**
\`\`\`bash
PORT=3001 npm run dev
\`\`\`

**Node.js version issues:**
The script automatically installs Node.js 20+ which is required.

## Manual Installation

If you prefer manual installation or need more control:

### 1. Install PostgreSQL
\`\`\`bash
sudo apt update
sudo apt install postgresql postgresql-contrib
\`\`\`

### 2. Create Database
\`\`\`bash
sudo -u postgres psql
CREATE DATABASE isp_system;
CREATE USER isp_admin WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE isp_system TO isp_admin;
\`\`\`

### 3. Run Migrations
\`\`\`bash
for script in scripts/*.sql; do
  sudo -u postgres psql -d isp_system -f "$script"
done
\`\`\`

### 4. Configure Environment
Create `.env.local`:
\`\`\`env
DATABASE_URL="postgresql://isp_admin:your_password@localhost:5432/isp_system"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
JWT_SECRET="your-secret-key"
\`\`\`

### 5. Install and Build
\`\`\`bash
npm install
npm run build
npm start
\`\`\`

## Security Notes

⚠️ **Important:** After installation:
1. Note the database credentials from `database-credentials.txt`
2. Delete `database-credentials.txt` after saving credentials securely
3. Change default admin password on first login
4. Keep `.env.local` secure (it's in `.gitignore`)
5. Use strong passwords in production
6. Configure firewall rules for production deployment

## Features Included

The installed system includes:
- 👥 Customer Management & Portal
- 💰 Billing & Invoicing
- 🌐 Network Management
- 👔 HR & Payroll
- 📊 Financial Reporting
- 🎫 Support Tickets
- 📦 Inventory Management
- 🚗 Fleet Management
- 📱 SMS & Notifications

## Support

For issues or questions:
- Check application logs: `npm run dev` output
- Review database logs: `sudo journalctl -u postgresql`
- Verify database connection: `psql -U isp_admin -d isp_system`
- Check environment variables in `.env.local`

## Uninstallation

To remove the system:

\`\`\`bash
# Stop the service (if installed)
sudo systemctl stop isp-system
sudo systemctl disable isp-system
sudo rm /etc/systemd/system/isp-system.service

# Remove database
sudo -u postgres psql -c "DROP DATABASE isp_system;"
sudo -u postgres psql -c "DROP USER isp_admin;"

# Remove application files
cd .. && rm -rf isp-management-system
