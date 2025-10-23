# Node.js Upgrade Guide

Your ISP Management System is currently running with Node.js v12, which has limited functionality. To unlock full features and optimal performance, please upgrade to Node.js 20+.

## Why Upgrade?

- **Full Feature Support**: Node.js v12 doesn't support modern JavaScript features used in this application
- **Better Performance**: Node.js 20 is significantly faster and more efficient
- **Security**: Node.js 12 is no longer maintained and has known security vulnerabilities
- **Compatibility**: Next.js 14+ requires Node.js 18.17 or later

## Upgrade Methods

### Option 1: Snap (Recommended - Easiest)

\`\`\`bash
# Install Node.js 20 via snap
sudo snap install node --classic --channel=20/stable

# Add snap to your PATH
export PATH="/snap/bin:$PATH"
echo 'export PATH="/snap/bin:$PATH"' >> ~/.bashrc

# Verify installation
node --version  # Should show v20.x.x
\`\`\`

### Option 2: NodeSource Repository

\`\`\`bash
# Download and run NodeSource setup script
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt-get install -y nodejs

# Verify installation
node --version  # Should show v20.x.x
\`\`\`

### Option 3: NVM (Node Version Manager)

\`\`\`bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Reload shell configuration
source ~/.bashrc

# Install Node.js 20
nvm install 20

# Set as default
nvm use 20
nvm alias default 20

# Verify installation
node --version  # Should show v20.x.x
\`\`\`

## After Upgrading

Once Node.js 20 is installed, rebuild your application:

\`\`\`bash
# Navigate to project directory
cd /path/to/isp-system

# Reinstall dependencies with new Node.js version
npm install

# Rebuild the application
npm run build

# Start the system
npm run dev
\`\`\`

## Troubleshooting

### "node: command not found" after snap installation

\`\`\`bash
export PATH="/snap/bin:$PATH"
echo 'export PATH="/snap/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
\`\`\`

### Multiple Node.js versions installed

\`\`\`bash
# Check which node is being used
which node

# If using nvm, set default
nvm alias default 20
nvm use 20
\`\`\`

### Permission errors during npm install

\`\`\`bash
# Fix npm permissions
sudo chown -R $USER:$USER ~/.npm
sudo chown -R $USER:$USER node_modules
\`\`\`

## Verification

After upgrading and rebuilding, verify everything works:

\`\`\`bash
# Check Node.js version
node --version  # Should be v18+ or v20+

# Check npm version
npm --version

# Start the application
npm run dev

# Open browser to http://localhost:3000
\`\`\`

## Need Help?

If you encounter issues during the upgrade:

1. Check the error messages carefully
2. Ensure you have sudo/root access
3. Try a different installation method
4. Run the auto-install.sh script again after upgrading Node.js

The system will work with Node.js v12 but with reduced functionality. Upgrading to Node.js 20 is strongly recommended for the best experience.
