#!/bin/bash

# Ghana School MIS Deployment Script
# For production deployment on Ubuntu/Debian servers

set -e

# Configuration
APP_NAME="ghana-school-mis"
APP_DIR="/opt/$APP_NAME"
GIT_REPO="https://github.com/yourusername/ghana-school-mis.git"
BRANCH="main"
NODE_ENV="production"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        missing_deps+=("Node.js")
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        missing_deps+=("Git")
    fi
    
    # Check PM2
    if ! command -v pm2 &> /dev/null; then
        missing_deps+=("PM2")
    fi
    
    # Check Nginx
    if ! command -v nginx &> /dev/null; then
        missing_deps+=("Nginx")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Run ./scripts/setup.sh first to install dependencies"
        exit 1
    fi
    
    log_info "All dependencies are installed"
}

setup_application() {
    log_info "Setting up application..."
    
    # Create application directory
    if [ ! -d "$APP_DIR" ]; then
        log_info "Creating application directory..."
        mkdir -p "$APP_DIR"
        chown -R $USER:$USER "$APP_DIR"
    fi
    
    # Clone or update repository
    if [ ! -d "$APP_DIR/.git" ]; then
        log_info "Cloning repository..."
        git clone "$GIT_REPO" "$APP_DIR"
    else
        log_info "Updating repository..."
        cd "$APP_DIR"
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
    fi
    
    # Set permissions
    chown -R $USER:$USER "$APP_DIR"
    chmod -R 755 "$APP_DIR"
}

install_dependencies() {
    log_info "Installing dependencies..."
    
    cd "$APP_DIR"
    
    # Install root dependencies
    if [ -f "package.json" ]; then
        npm install --production
    fi
    
    # Install backend dependencies
    if [ -d "backend" ]; then
        cd "$APP_DIR/backend"
        npm install --production
    fi
    
    # Install frontend dependencies and build
    if [ -d "frontend" ]; then
        cd "$APP_DIR/frontend"
        npm install --production
        npm run build
    fi
    
    log_info "Dependencies installed successfully"
}

configure_environment() {
    log_info "Configuring environment..."
    
    cd "$APP_DIR"
    
    # Copy environment files if they don't exist
    if [ -f "backend/.env.example" ] && [ ! -f "backend/.env" ]; then
        cp backend/.env.example backend/.env
        log_warn "Please edit backend/.env with your configuration"
    fi
    
    # Create uploads directory
    mkdir -p "$APP_DIR/backend/uploads"
    mkdir -p "$APP_DIR/backend/logs"
    mkdir -p "$APP_DIR/database/backups"
    
    # Set permissions
    chmod -R 755 "$APP_DIR/backend/uploads"
    chown -R $USER:$USER "$APP_DIR"
}

configure_nginx() {
    log_info "Configuring Nginx..."
    
    # Create Nginx configuration
    cat > /tmp/school-mis-nginx.conf << EOF
server {
    listen 80;
    server_name _;
    root ${APP_DIR}/frontend/dist;
    index index.html;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Frontend
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Uploads
    location /uploads {
        alias ${APP_DIR}/backend/uploads;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF
    
    # Install configuration
    sudo cp /tmp/school-mis-nginx.conf /etc/nginx/sites-available/school-mis
    sudo ln -sf /etc/nginx/sites-available/school-mis /etc/nginx/sites-enabled/
    
    # Test and reload Nginx
    sudo nginx -t
    sudo systemctl restart nginx
    
    log_info "Nginx configured successfully"
}

setup_pm2() {
    log_info "Setting up PM2..."
    
    cd "$APP_DIR"
    
    # Stop existing instances
    pm2 delete "$APP_NAME" 2>/dev/null || true
    
    # Start application
    if [ -f "ecosystem.config.js" ]; then
        pm2 start ecosystem.config.js
    else
        # Create PM2 configuration if it doesn't exist
        cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: '${APP_NAME}-backend',
    script: './backend/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production'
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '1G'
  }]
};
EOF
        pm2 start ecosystem.config.js
    fi
    
    # Save PM2 configuration
    pm2 save
    pm2 startup 2>/dev/null || true
    
    log_info "PM2 setup complete"
}

setup_database() {
    log_info "Setting up database..."
    
    # Start MongoDB if installed
    if command -v mongod &> /dev/null; then
        sudo systemctl start mongod
        sudo systemctl enable mongod
    fi
    
    # Initialize database if SQL scripts exist
    if [ -f "$APP_DIR/database/init.sql" ] && command -v mysql &> /dev/null; then
        log_info "Initializing database..."
        mysql -u root -p < "$APP_DIR/database/init.sql"
    fi
    
    log_info "Database setup complete"
}

setup_backup() {
    log_info "Setting up automated backups..."
    
    # Create backup script
    cat > "$APP_DIR/scripts/backup.sh" << 'EOF'
#!/bin/bash
# Backup script for Ghana School MIS

BACKUP_DIR="/opt/school-mis/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="school-mis-backup-$DATE"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup MongoDB
if command -v mongodump &> /dev/null; then
    mongodump --out "$BACKUP_DIR/$BACKUP_NAME/mongodb"
fi

# Backup MySQL
if command -v mysqldump &> /dev/null; then
    mysqldump --all-databases > "$BACKUP_DIR/$BACKUP_NAME/mysql.sql"
fi

# Backup application files
cp -r /opt/school-mis/backend/uploads "$BACKUP_DIR/$BACKUP_NAME/uploads"
cp /opt/school-mis/backend/.env "$BACKUP_DIR/$BACKUP_NAME/"

# Create archive
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME"

# Cleanup
rm -rf "$BACKUP_DIR/$BACKUP_NAME"

# Remove old backups (keep last 30 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
EOF
    
    chmod +x "$APP_DIR/scripts/backup.sh"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "backup.sh"; echo "0 2 * * * $APP_DIR/scripts/backup.sh") | crontab -
    
    log_info "Backup system configured"
}

setup_monitoring() {
    log_info "Setting up monitoring..."
    
    # Install monitoring tools
    sudo apt-get install -y htop
    
    # Create health check endpoint
    cat > "$APP_DIR/scripts/health-check.sh" << 'EOF'
#!/bin/bash
# Health check script

API_URL="http://localhost:5000/health"
LOG_FILE="/opt/school-mis/logs/health-check.log"

response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" || echo "000")

if [ "$response" -eq 200 ]; then
    echo "$(date): OK - Status $response" >> "$LOG_FILE"
else
    echo "$(date): ERROR - Status $response" >> "$LOG_FILE"
    # Restart service if health check fails
    cd /opt/school-mis
    pm2 restart all
fi
EOF
    
    chmod +x "$APP_DIR/scripts/health-check.sh"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "health-check.sh"; echo "*/5 * * * * $APP_DIR/scripts/health-check.sh") | crontab -
    
    log_info "Monitoring setup complete"
}

setup_ssl() {
    log_info "Setting up SSL (Let's Encrypt)..."
    
    if command -v certbot &> /dev/null; then
        read -p "Enter your domain name: " DOMAIN
        
        sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@$DOMAIN
        
        # Update Nginx configuration for SSL
        sudo sed -i "s/listen 80;/listen 80;\n    listen 443 ssl http2;/" /etc/nginx/sites-available/school-mis
        sudo sed -i "s/server_name _;/server_name $DOMAIN;/" /etc/nginx/sites-available/school-mis
        
        sudo nginx -t
        sudo systemctl reload nginx
        
        log_info "SSL certificate installed for $DOMAIN"
    else
        log_warn "Certbot not installed. SSL setup skipped."
        log_info "To install SSL later, run: sudo apt-get install certbot python3-certbot-nginx"
    fi
}

show_summary() {
    log_info "========================================="
    log_info "  Ghana School MIS Deployment Complete!  "
    log_info "========================================="
    echo ""
    log_info "Application Details:"
    echo "  - Directory: $APP_DIR"
    echo "  - Frontend: http://localhost (or your server IP)"
    echo "  - Backend API: http://localhost:5000"
    echo "  - API Docs: http://localhost:5000/api-docs"
    echo ""
    log_info "Management Commands:"
    echo "  - Start: pm2 start $APP_NAME"
    echo "  - Stop: pm2 stop $APP_NAME"
    echo "  - Restart: pm2 restart $APP_NAME"
    echo "  - Logs: pm2 logs $APP_NAME"
    echo "  - Status: pm2 status"
    echo ""
    log_info "Configuration Files:"
    echo "  - Environment: $APP_DIR/backend/.env"
    echo "  - Nginx: /etc/nginx/sites-available/school-mis"
    echo "  - PM2: $APP_DIR/ecosystem.config.js"
    echo ""
    log_info "Backup & Monitoring:"
    echo "  - Backups: Daily at 2 AM to $APP_DIR/backups/"
    echo "  - Health checks: Every 5 minutes"
    echo ""
    log_info "Support:"
    echo "  - Documentation: $APP_DIR/docs/"
    echo "  - Issues: https://github.com/yourusername/ghana-school-mis/issues"
    echo ""
    log_info "Next Steps:"
    echo "1. Edit $APP_DIR/backend/.env with your configuration"
    echo "2. Configure your domain in Nginx if needed"
    echo "3. Set up SSL certificates (recommended)"
    echo "4. Initialize the database with sample data"
    echo ""
    log_info "To initialize the database:"
    echo "  cd $APP_DIR/database"
    echo "  mysql -u root -p < init.sql"
    echo "  mysql -u root -p < sample_data.sql"
    echo ""
    log_info "========================================="
}

main() {
    log_info "Starting Ghana School MIS deployment..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        log_error "Please run as root or use sudo"
        exit 1
    fi
    
    # Execute deployment steps
    check_dependencies
    setup_application
    install_dependencies
    configure_environment
    configure_nginx
    setup_pm2
    setup_database
    setup_backup
    setup_monitoring
    
    # Ask about SSL
    read -p "Do you want to set up SSL (Let's Encrypt)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_ssl
    fi
    
    show_summary
    
    log_info "Deployment completed successfully!"
}

# Run main function
main "$@"
