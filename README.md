# ISP Management System - Easy Deployment

A comprehensive Internet Service Provider (ISP) management system with automated deployment using Docker.

## 🚀 Quick Start (One-Command Installation)

### Prerequisites
- Linux (Ubuntu/Debian) or macOS
- Internet connection
- At least 4GB RAM and 10GB free disk space

### Installation

1. **Download and extract the system:**
   \`\`\`bash
   # Download the system files to your desired directory
   cd /path/to/your/installation/directory
   \`\`\`

2. **Run the installation script:**
   \`\`\`bash
   chmod +x install.sh
   ./install.sh
   \`\`\`

The installation script will automatically:
- ✅ Install Docker and Docker Compose
- ✅ Download all required software (MySQL, RADIUS, OpenVPN, Redis, Nginx)
- ✅ Set up the database with all tables and initial data
- ✅ Configure networking and security
- ✅ Start all services
- ✅ Provide you with access URLs and credentials

### Access Your System

After installation completes (usually 5-10 minutes), access:

- **🌐 Web Interface:** http://localhost:3000
- **🗄️ Database:** localhost:3306
- **🔐 RADIUS Server:** localhost:1812 (Auth), localhost:1813 (Accounting)
- **🔒 OpenVPN Server:** localhost:1194

### Default Credentials

**Database:**
- Username: `isp_user`
- Password: `isp_password_2024`
- Database: `isp_system`

**Web Interface:**
- Access the web interface and create your admin account on first visit

## 🛠️ System Management

### Start/Stop the System
\`\`\`bash
# Stop the system
docker-compose down

# Start the system
docker-compose up -d

# Restart the system
docker-compose restart

# View logs
docker-compose logs -f
\`\`\`

### Update the System
\`\`\`bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up -d --build
\`\`\`

### Backup Data
\`\`\`bash
# Backup database
docker exec isp_mysql mysqldump -u isp_user -pisp_password_2024 isp_system > backup.sql

# Backup all data volumes
docker run --rm -v isp_system_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_backup.tar.gz -C /data .
\`\`\`

## 📋 System Components

### Included Services
- **Next.js Application** - Main ISP management interface
- **MySQL 8.0** - Primary database
- **FreeRADIUS** - Authentication server for network access
- **OpenVPN** - VPN server for remote access
- **Redis** - Caching and session storage
- **Nginx** - Reverse proxy and load balancer

### Features
- 👥 Customer Management
- 💰 Billing and Payments (M-Pesa integration)
- 🌐 Network Management and Monitoring
- 🎫 Support Ticket System
- 📊 Reports and Analytics
- 👨‍💼 HR Management
- 🚗 Vehicle Management
- 📱 SMS/Communication System
- ⚙️ System Configuration
- 📝 Comprehensive Logging

## 🔧 Configuration

### Environment Variables
Edit `.env` file to customize:
\`\`\`bash
# Database settings
DATABASE_URL=mysql://isp_user:isp_password_2024@mysql:3306/isp_system
POSTGRES_HOST=mysql
POSTGRES_USER=isp_user
POSTGRES_PASSWORD=isp_password_2024

# Security (CHANGE IN PRODUCTION!)
NEXTAUTH_SECRET=your-secret-key-here-change-this-in-production
\`\`\`

### Port Configuration
Default ports used:
- `3000` - Web interface
- `3306` - MySQL database
- `1812/1813` - RADIUS server
- `1194` - OpenVPN server
- `6379` - Redis
- `80/443` - Nginx proxy

To change ports, edit `docker-compose.yml`.

## 🔒 Security Considerations

### Production Deployment
1. **Change default passwords** in `.env` file
2. **Enable HTTPS** by configuring SSL certificates in nginx
3. **Configure firewall** to restrict access to necessary ports only
4. **Regular backups** of database and configuration
5. **Update system** regularly for security patches

### SSL/HTTPS Setup
1. Obtain SSL certificates (Let's Encrypt recommended)
2. Place certificates in `./ssl/` directory
3. Update `nginx.conf` to enable HTTPS

## 🆘 Troubleshooting

### Common Issues

**Services won't start:**
\`\`\`bash
# Check logs
docker-compose logs

# Check system resources
docker system df
free -h
\`\`\`

**Database connection issues:**
\`\`\`bash
# Check MySQL status
docker-compose exec mysql mysql -u isp_user -pisp_password_2024 -e "SELECT 1"

# Reset database
docker-compose down
docker volume rm isp_system_mysql_data
docker-compose up -d
\`\`\`

**Port conflicts:**
\`\`\`bash
# Check what's using ports
sudo netstat -tulpn | grep :3000
sudo lsof -i :3000

# Stop conflicting services or change ports in docker-compose.yml
\`\`\`

### Getting Help
- Check logs: `docker-compose logs -f [service_name]`
- Restart specific service: `docker-compose restart [service_name]`
- Full system reset: `docker-compose down -v && docker-compose up -d`

## 📈 Scaling and Performance

### For High Traffic
1. **Increase resources** in `docker-compose.yml`
2. **Add load balancing** with multiple app instances
3. **Database optimization** with read replicas
4. **Redis clustering** for session management

### Monitoring
- Built-in system monitoring dashboard
- Log aggregation and analysis
- Performance metrics and alerts
- Network monitoring and diagnostics

## 🔄 Updates and Maintenance

The system includes:
- Automated database migrations
- Configuration backup and restore
- Health checks for all services
- Automated log rotation
- System maintenance tools

---

**Need help?** Check the logs first, then consult the troubleshooting section above.
