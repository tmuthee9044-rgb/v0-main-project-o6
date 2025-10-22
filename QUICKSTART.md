# ISP Management System - Quick Start Guide

## 🚀 SIMPLEST INSTALLATION (RECOMMENDED)

**Just copy and paste this ONE command:**

\`\`\`bash
wget -O - https://raw.githubusercontent.com/tmuthee9044-rgb/v0-main-project-o6/main/quick-install.sh | bash
\`\`\`

**OR if wget doesn't work, use curl:**

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/tmuthee9044-rgb/v0-main-project-o6/main/quick-install.sh | bash
\`\`\`

This single command will:
- ✅ Download the entire project
- ✅ Install PostgreSQL database
- ✅ Install Node.js 20
- ✅ Create database and all tables
- ✅ Install all dependencies
- ✅ Configure everything automatically

**Takes 5-10 minutes. After completion:**

\`\`\`bash
cd isp-system
npm run dev
\`\`\`

Then open **http://localhost:3000** in your browser.

---

## 📦 ALTERNATIVE: Manual Download (If Above Doesn't Work)

If the one-command installation doesn't work, follow these manual steps:

### Step 1: Download the Project

\`\`\`bash
# Using wget
wget https://github.com/tmuthee9044-rgb/v0-main-project-o6/archive/refs/heads/main.zip -O isp-system.zip

# OR using curl
curl -L https://github.com/tmuthee9044-rgb/v0-main-project-o6/archive/refs/heads/main.zip -o isp-system.zip
\`\`\`

### Step 2: Extract and Install

\`\`\`bash
# Install unzip if needed
sudo apt install unzip

# Extract the files
unzip isp-system.zip

# Rename and enter directory
mv v0-main-project-o6-main isp-system
cd isp-system

# Run installer
chmod +x install.sh
./install.sh
\`\`\`

### Step 3: Start the System

\`\`\`bash
npm run dev
\`\`\`

Open **http://localhost:3000**

---

## 🔧 If You Have Issues

### Issue: "sudo: cannot execute binary file"

Your sudo is broken. Fix it as root:

\`\`\`bash
# Become root
su -

# Fix sudo
apt-get update
apt-get install --reinstall sudo
chmod +x /usr/bin/sudo

# Exit root
exit
\`\`\`

Then try the installation again.

### Issue: "wget: command not found" AND "curl: command not found"

Install one of them:

\`\`\`bash
# Become root if sudo is broken
su -

# Install wget
apt-get update
apt-get install wget

# Exit root
exit
\`\`\`

Then try the installation again.

### Issue: "Permission denied"

Make sure you're NOT running as root:

\`\`\`bash
# Check current user
whoami

# If it says "root", exit and run as regular user
exit
\`\`\`

---

## 📋 What Gets Installed

- **PostgreSQL 15+** - Database server (runs locally)
- **Node.js 20+** - JavaScript runtime
- **All dependencies** - Automatically installed
- **Database tables** - All 50+ tables created automatically
- **Sample data** - Optional test data

---

## 🎯 After Installation

### Start the System

\`\`\`bash
# Development mode (with hot reload)
npm run dev

# Production mode
npm run build
npm start
\`\`\`

### Access the System

- **URL:** http://localhost:3000
- **Database credentials:** Saved in `database-credentials.txt`
- **Environment variables:** Auto-configured in `.env.local`

### Default Login

The system will prompt you to create an admin account on first run.

---

## 💡 System Requirements

- **OS:** Ubuntu 20.04+ / Debian 11+ / Linux Mint 20+
- **RAM:** 2GB minimum (4GB recommended)
- **Disk:** 2GB free space
- **Internet:** Required for initial installation only

---

## 🆘 Need Help?

If you're still having issues:

1. Check that you have internet connection
2. Make sure you're not running as root user
3. Try the manual download method above
4. Check the INSTALL.md file for detailed troubleshooting

---

## 🔒 Security Note

All database credentials are randomly generated and saved locally. The system runs entirely on your machine - no data is sent externally.
