# 🚀 Quick Start - One Command Installation

## Install Everything in One Command

Copy and paste this single command to install the complete ISP Management System:

\`\`\`bash
git clone https://github.com/tmuthee9044-rgb/v0-main-project-o6.git isp-system && cd isp-system && chmod +x install.sh && ./install.sh
\`\`\`

That's it! This command will:

✅ Download the system from GitHub  
✅ Install PostgreSQL database server  
✅ Create the `isp_system` database locally  
✅ Run all 150+ SQL scripts to create tables  
✅ Install Node.js 20+ (if needed)  
✅ Install all dependencies  
✅ Build the application  
✅ Configure environment variables  
✅ Generate secure database credentials  

## What Happens Next?

After the installation completes (takes 5-10 minutes):

### 1. Your database credentials will be saved in:
- `database-credentials.txt` - Keep this secure!
- `.env.local` - Auto-configured connection strings

### 2. Start the system:

**Development mode** (with hot reload):
\`\`\`bash
npm run dev
\`\`\`

**Production mode**:
\`\`\`bash
npm start
\`\`\`

### 3. Access the system:
Open your browser to: **http://localhost:3000**

### 4. First-time setup:
- Create your admin account
- Configure company settings
- Start managing your ISP!

## System Requirements

- **OS:** Ubuntu 20.04+, Debian 11+, macOS 10.15+, or Windows WSL2
- **RAM:** 2GB minimum (4GB recommended)
- **Disk Space:** 2GB for application + database
- **Sudo Access:** Required for installing PostgreSQL

## Offline Capability

Once installed, the system works **100% offline**:
- ✅ Local PostgreSQL database
- ✅ All dependencies installed locally
- ✅ No external API dependencies
- ✅ No internet connection required

## Troubleshooting

### Permission denied error:
\`\`\`bash
chmod +x install.sh
./install.sh
\`\`\`

### Port 3000 already in use:
\`\`\`bash
PORT=3001 npm run dev
\`\`\`

### PostgreSQL connection error:
Check your credentials in `.env.local` and `database-credentials.txt`

### Need to reinstall:
\`\`\`bash
./install.sh  # The script will drop and recreate the database
\`\`\`

## What's Included?

The installed system includes all these modules:

- 👥 **Customer Management** - Complete customer lifecycle
- 💰 **Billing & Invoicing** - Automated billing with M-Pesa integration
- 🌐 **Network Management** - IP allocation, routers, monitoring
- 👔 **HR & Payroll** - Employee management and payroll processing
- 📊 **Financial Reporting** - Comprehensive accounting and reports
- 🎫 **Support Tickets** - Customer service management
- 📦 **Inventory Management** - Equipment and stock tracking
- 🚗 **Fleet Management** - Vehicle and maintenance tracking
- 📱 **SMS & Notifications** - Automated customer communications
- 🔐 **Role-Based Access** - Secure user permissions
- 📈 **Analytics Dashboard** - Real-time business insights

## Database Structure

The installation creates **50+ tables** including:

- `customers` - Customer information and accounts
- `service_plans` - Internet packages and pricing
- `customer_services` - Active customer subscriptions
- `invoices` & `payments` - Billing and payment tracking
- `network_devices` - Routers, switches, access points
- `ip_addresses` & `subnets` - IP address management
- `employees` & `payroll` - HR and payroll data
- `support_tickets` - Customer support tracking
- `inventory_items` - Equipment and stock
- And 40+ more tables for complete ISP operations

## Security Notes

⚠️ **After installation:**

1. **Save your database credentials** from `database-credentials.txt`
2. **Delete** `database-credentials.txt` after saving credentials
3. **Change default passwords** on first login
4. **Keep** `.env.local` secure (already in `.gitignore`)
5. **Use strong passwords** in production
6. **Configure firewall** for production deployment

## Next Steps

After installation:

1. **Read the User Guide:** `docs/user-guide.md`
2. **Configure Company Settings:** Set your ISP name, logo, currency
3. **Add Service Plans:** Create your internet packages
4. **Import Customers:** Bulk import or add manually
5. **Configure M-Pesa:** For automated payment collection (optional)
6. **Set Up Network:** Add routers and configure IP pools
7. **Train Your Team:** Add staff users with appropriate roles

## Support

For help:
- 📖 Check `INSTALL.md` for detailed installation guide
- 🐛 Check `docs/troubleshooting.md` for common issues
- 📧 Review application logs: `npm run dev` output
- 🗄️ Check database logs: `sudo journalctl -u postgresql`

## Uninstall

To completely remove the system:

\`\`\`bash
# Stop the service (if installed)
sudo systemctl stop isp-system
sudo systemctl disable isp-system

# Remove database
sudo -u postgres psql -c "DROP DATABASE isp_system;"
sudo -u postgres psql -c "DROP USER isp_admin;"

# Remove application
cd .. && rm -rf isp-system
\`\`\`

---

**Ready to get started?** Just run the one-command installation at the top of this page! 🚀
