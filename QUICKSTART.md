# ISP Management System - Quick Start Guide

## 🚀 ONE-COMMAND INSTALLATION

Run this single command to install everything:

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/tmuthee9044-rgb/v0-main-project-o6/main/setup.sh | bash
\`\`\`

This will automatically:
- Install Git (if needed)
- Download the project
- Install PostgreSQL
- Create the database
- Install Node.js 20
- Install all dependencies
- Build the system
- Configure everything

**Installation takes 5-10 minutes. After completion:**

\`\`\`bash
cd isp-system
npm run dev
\`\`\`

Then open http://localhost:3000

---

## 🔧 If You Have Sudo Issues

If you get "sudo: cannot execute binary file" error, run these commands first:

\`\`\`bash
# Become root
su -

# Fix sudo
apt-get update && apt-get install --reinstall sudo
chmod +x /usr/bin/sudo

# Add your user to sudo group (replace YOUR_USERNAME)
usermod -aG sudo YOUR_USERNAME

# Exit root
exit
\`\`\`

Then log out and log back in, and run the one-command installation above.

---

## 📦 Alternative: Manual Download (No Git Required)

If you can't install Git or prefer not to use it:

1. **Download ZIP file:**
   - Go to: https://github.com/tmuthee9044-rgb/v0-main-project-o6
   - Click the green "Code" button
   - Click "Download ZIP"

2. **Extract and install:**
   \`\`\`bash
   unzip v0-main-project-o6-main.zip
   cd v0-main-project-o6-main
   chmod +x install.sh
   ./install.sh
   \`\`\`

---

## 📋 What Gets Installed

- **PostgreSQL 15+** - Database server
- **Node.js 20+** - JavaScript runtime
- **npm packages** - All project dependencies
- **Database** - `isp_system` with all tables
- **Environment variables** - Auto-configured in `.env.local`

---

## 🎯 After Installation

1. **Start the system:**
   \`\`\`bash
   npm run dev          # Development mode
   # OR
   npm start            # Production mode
   \`\`\`

2. **Access the system:**
   - URL: http://localhost:3000
   - Default admin credentials created on first run

3. **Database credentials:**
   - Saved in `database-credentials.txt`
   - Also in `.env.local`

---

## Troubleshooting

### "sudo: cannot execute binary file" error:

This is a serious system issue. Try these fixes in order:

**Fix 1: Reinstall sudo (requires root access)**
\`\`\`bash
# Switch to root user
su -

# Reinstall sudo
apt-get update
apt-get install --reinstall sudo

# Make sure sudo is executable
chmod +x /usr/bin/sudo

# Add your user to sudo group
usermod -aG sudo YOUR_USERNAME

# Exit root
exit

# Log out and log back in for changes to take effect
\`\`\`

**Fix 2: Check system architecture**
\`\`\`bash
# Check if you're running the right architecture
uname -m
file /usr/bin/sudo

# If there's a mismatch, you may need to reinstall your OS
\`\`\`

**Fix 3: Use root to install (not recommended for production)**
\`\`\`bash
# Switch to root
su -

# Run installation as root (modify install.sh to skip sudo checks)
cd /path/to/isp-system
bash install.sh
\`\`\`

### "git: command not found" error:
Install Git using the instructions at the top of this page, then try again.
