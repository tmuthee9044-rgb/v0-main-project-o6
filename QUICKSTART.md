# ISP Management System - Quick Start Guide

## ⚡ SUPER SIMPLE INSTALLATION

**You tried to run `npm start` but you're not in the project folder yet!**

**Follow these commands ONE BY ONE:**

\`\`\`bash
# Step 1: Download the project
wget https://github.com/tmuthee9044-rgb/v0-main-project-o6/archive/refs/heads/main.zip -O isp.zip

# Step 2: Extract it
unzip isp.zip

# Step 3: Rename and enter the folder
mv v0-main-project-o6-main isp-system
cd isp-system

# Step 4: Make installer executable
chmod +x install.sh

# Step 5: Run the installer (this takes 5-10 minutes)
./install.sh

# Step 6: Start the system
npm run dev
\`\`\`

**Then open http://localhost:3000 in your browser!**

---

## 🔧 If wget or unzip is missing

**Run this first:**

\`\`\`bash
# If sudo works:
sudo apt update && sudo apt install -y wget unzip

# If sudo is broken, become root:
su -
apt update && apt install -y wget unzip
exit
\`\`\`

**Then run the 6 steps above.**

---

## 🚀 ONE-COMMAND INSTALLATION (All Steps Combined)

**If you want to do everything in one command:**

\`\`\`bash
wget https://github.com/tmuthee9044-rgb/v0-main-project-o6/archive/refs/heads/main.zip -O isp.zip && unzip isp.zip && mv v0-main-project-o6-main isp-system && cd isp-system && chmod +x install.sh && ./install.sh
\`\`\`

**After it finishes, run:**

\`\`\`bash
cd isp-system
npm run dev
\`\`\`

## 🛠️ TROUBLESHOOTING

### Problem: "npm error ERESOLVE unable to resolve dependency tree"

**This is now FIXED!** The updated package.json and install.sh handle this automatically.

If you downloaded the project before this fix:

\`\`\`bash
# Delete the old project
rm -rf isp-system

# Download the updated version
wget https://github.com/tmuthee9044-rgb/v0-main-project-o6/archive/refs/heads/main.zip -O isp.zip
unzip isp.zip
mv v0-main-project-o6-main isp-system
cd isp-system
chmod +x install.sh
./install.sh
\`\`\`

### Problem: "Unsupported engine" or "Node.js 18.x detected"

**This is now FIXED!** The install.sh now automatically installs Node.js 20.

The system requires Node.js 20+. The installer will upgrade automatically.

### Problem: "sudo: cannot execute binary file"

Your sudo is corrupted. Fix it as root:

\`\`\`bash
# Become root
su -

# Reinstall sudo
apt update
apt install --reinstall sudo
chmod +x /usr/bin/sudo

# Add your user to sudo group (replace 'ispman' with your username)
usermod -aG sudo ispman

# Exit root
exit

# Log out and log back in for changes to take effect
\`\`\`

Then try the installation again.

### Problem: "wget: command not found"

Install wget as root:

\`\`\`bash
# Become root
su -

# Install wget and unzip
apt update
apt install -y wget unzip

# Exit root
exit
\`\`\`

Then run the one-command installation.

### Problem: "unzip: command not found"

Install unzip:

\`\`\`bash
# If sudo works
sudo apt install -y unzip

# If sudo is broken
su -
apt install -y unzip
exit
\`\`\`

### Problem: Installation fails or hangs

Try the **manual step-by-step method** below.

---

## 📦 MANUAL INSTALLATION (Step-by-Step)

If the one-command installation doesn't work, follow these steps:

### Step 1: Download the Project

\`\`\`bash
wget https://github.com/tmuthee9044-rgb/v0-main-project-o6/archive/refs/heads/main.zip -O isp.zip
\`\`\`

### Step 2: Extract Files

\`\`\`bash
unzip isp.zip
mv v0-main-project-o6-main isp-system
cd isp-system
\`\`\`

### Step 3: Make Install Script Executable

\`\`\`bash
chmod +x install.sh
\`\`\`

### Step 4: Run Installation

\`\`\`bash
./install.sh
\`\`\`

The installer will:
- Check and install PostgreSQL
- Check and install Node.js 20+ (upgrades from 18 if needed)
- Create database `isp_system`
- Create all tables (50+ tables)
- Install npm dependencies with --legacy-peer-deps
- Build the application
- Generate secure credentials

### Step 5: Start the System

\`\`\`bash
# Development mode (recommended for testing)
npm run dev

# OR Production mode
npm run build
npm start
\`\`\`

### Step 6: Access the System

Open your browser and go to: **http://localhost:3000**

---

## 📋 What Gets Installed

The installation script automatically installs:

- **PostgreSQL 15+** - Local database server
- **Node.js 20+** - JavaScript runtime (upgrades from 18 if needed)
- **npm packages** - All project dependencies (with compatibility fixes)
- **Database schema** - 50+ tables with relationships
- **Sample data** - Test data for development
- **Environment config** - Auto-generated `.env.local`

---

## 🎯 After Installation

### Database Credentials

Your database credentials are saved in:
- `database-credentials.txt` - Database username/password
- `.env.local` - Environment variables

**⚠️ Keep these files secure!**

### Starting the System

\`\`\`bash
# Development mode (with hot reload)
npm run dev

# Production mode (optimized)
npm run build
npm start
\`\`\`

### Accessing the System

- **URL:** http://localhost:3000
- **Admin setup:** Create admin account on first visit
- **Database:** Runs locally on port 5432

---

## 💻 System Requirements

- **OS:** Ubuntu 20.04+ / Debian 11+ / Linux Mint 20+
- **RAM:** 2GB minimum (4GB recommended)
- **Disk:** 2GB free space
- **Ports:** 3000 (web), 5432 (database)
- **Internet:** Required for initial installation only
- **Node.js:** 20.0.0 or higher (installer handles this)

---

## 🔒 Security Features

- Database credentials randomly generated
- Passwords hashed with bcrypt
- JWT tokens for authentication
- All data stored locally
- No external data transmission

---

## 📚 Next Steps

After installation:

1. **Create admin account** - First time you visit http://localhost:3000
2. **Configure company settings** - Update company name, logo, etc.
3. **Add service plans** - Define your internet packages
4. **Add customers** - Start managing your ISP
5. **Explore features** - Billing, support tickets, network monitoring

---

## 🆘 Still Having Issues?

### Check Installation Logs

The installer shows detailed logs. Look for error messages.

### Verify Prerequisites

\`\`\`bash
# Check PostgreSQL
sudo systemctl status postgresql

# Check Node.js (should be 20.x or higher)
node --version

# Check npm
npm --version
\`\`\`

### Common Issues

1. **Port 3000 already in use** - Stop other services or change port
2. **Port 5432 already in use** - PostgreSQL already running
3. **Permission denied** - Don't run as root, use regular user
4. **Database connection failed** - Check PostgreSQL is running
5. **React version conflicts** - Fixed in latest version, re-download if needed

### Get Help

- Check `INSTALL.md` for detailed documentation
- Review `database-credentials.txt` for connection info
- Check logs in the terminal output

---

## 🎉 Installation Complete!

Once installed, you'll have a fully functional ISP management system with:

- Customer management
- Billing and invoicing
- Payment processing
- Support ticket system
- Network monitoring
- Employee management
- Financial reporting
- And much more!

**Start the system with `npm run dev` and visit http://localhost:3000**
