#!/bin/bash

# Ghana School MIS Setup Script
# Version: 1.0.0

set -e  # Exit on error

echo "========================================="
echo "  Ghana School MIS Setup Script"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_info() {
    echo -e "[i] $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_warning "Please run as root or use sudo"
    exit 1
fi

# Check system requirements
print_info "Checking system requirements..."

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed"
    print_info "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    print_success "Node.js installed"
else
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version must be >= 18. Current: $(node -v)"
        exit 1
    fi
    print_success "Node.js $(node -v) is installed"
fi

# Check npm
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed"
    apt-get install -y npm
    print_success "npm installed"
else
    print_success "npm $(npm -v) is installed"
fi

# Check MongoDB
if ! command -v mongod &> /dev/null; then
    print_warning "MongoDB is not installed"
    print_info "Installing MongoDB..."
    
    # Import MongoDB GPG key
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
    
    # Create list file
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    
    # Update packages
    apt-get update
    
    # Install MongoDB
    apt-get install -y mongodb-org
    
    # Start MongoDB
    systemctl start mongod
    systemctl enable mongod
    
    print_success "MongoDB installed and started"
else
    print_success "MongoDB is installed"
fi

# Check Git
if ! command -v git &> /dev/null; then
    print_info "Installing Git..."
    apt-get install -y git
    print_success "Git installed"
else
    print_success "Git $(git --version | cut -d' ' -f3) is installed"
fi

# Check Docker (optional)
if ! command -v docker &> /dev/null; then
    print_warning "Docker is not installed (optional for containerized deployment)"
else
    print_success "Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1) is installed"
fi

# Check Nginx
if ! command -v nginx &> /dev/null; then
    print_info "Installing Nginx..."
    apt-get install -y nginx
    print_success "Nginx installed"
else
    print_success "Nginx is installed"
fi

# Install PM2 for process management
print_info "Installing PM2..."
npm install -g pm2
print_success "PM2 installed"

# Create application directory
APP_DIR="/opt/school-mis"
print_info "Creating application directory at $APP_DIR..."
mkdir -p $APP_DIR
chown -R $SUDO_USER:$SUDO_USER $APP_DIR

# Clone or copy application files
print_info "Setting up application files..."

# If running from git repository
if [ -f "package.json" ]; then
    print_info "Copying existing application..."
    cp -r . $APP_DIR/
else
    print_info "Cloning from Git repository..."
    git clone https://github.com/yourusername/ghana-school-mis.git $APP_DIR
fi

# Set permissions
chown -R $SUDO_USER:$SUDO_USER $APP_DIR
chmod -R 755 $APP_DIR

# Install backend dependencies
print_info "Installing backend dependencies..."
cd $APP_DIR/backend
npm install --production
print_success "Backend dependencies installed"

# Install frontend dependencies
print_info "Installing frontend dependencies..."
cd $APP_DIR/frontend
npm install --production
npm run build
print_success "Frontend dependencies installed and built"

# Set up environment files
print_info "Setting up environment configuration..."
cd $APP_DIR

# Create .env file for backend
if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    print_warning "Please edit backend/.env with your configuration"
fi

# Set up Nginx configuration
print_info "Configuring Nginx..."
NGINX_CONF="/etc/nginx/sites-available/school-mis"
cat > $NGINX_CONF << 'EOF'
server {
    listen 80;
    server_name schoolmis.local;
    root /opt/school-mis/frontend/dist;
    index index.html;

    # Frontend
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Static files
    location /uploads {
        alias /opt/school-mis/backend/uploads;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}

# SSL configuration (uncomment and configure SSL certificates)
# server {
#     listen 443 ssl http2;
#     server_name schoolmis.local;
#     
#     ssl_certificate /etc/ssl/certs/schoolmis.crt;
#     ssl_certificate_key /etc/ssl/private/schoolmis.key;
#     
#     # Include the rest of the configuration from above
#     # ...
# }
EOF

# Enable the site
ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
print_success "Nginx configured"

# Set up PM2 startup
print_info "Setting up PM2 startup..."
cd $APP_DIR
pm2 start ecosystem.config.js
pm2 save
pm2 startup systemd -u $SUDO_USER --hp /home/$SUDO_USER
print_success "PM2 startup configured"

# Set up firewall
print_info "Configuring firewall..."
ufw allow 22/tcp  # SSH
ufw allow 80/tcp  # HTTP
ufw allow 443/tcp # HTTPS
ufw allow 5000/tcp # API (if not behind proxy)
ufw --force enable
print_success "Firewall configured"

# Set up database
print_info "Setting up database..."
cd $APP_DIR/database
if command -v mysql &> /dev/null; then
    mysql -u root -p < init.sql
    print_success "Database initialized"
else
    print_warning "MySQL not found, skipping database initialization"
fi

# Create necessary directories
print_info "Creating required directories..."
mkdir -p $APP_DIR/backend/uploads
mkdir -p $APP_DIR/backend/logs
mkdir -p $APP_DIR/database/backups
chmod -R 755 $APP_DIR/backend/uploads
chown -R $SUDO_USER:$SUDO_USER $APP_DIR

# Set up backup cron job
print_info "Setting up backup schedule..."
CRON_JOB="0 2 * * * $SUDO_USER cd $APP_DIR && ./scripts/backup.sh"
(crontab -l 2>/dev/null | grep -v "backup.sh"; echo "$CRON_JOB") | crontab -
print_success "Backup cron job scheduled"

# Create systemd service for MongoDB
if [ ! -f "/etc/systemd/system/mongod.service" ]; then
    cat > /etc/systemd/system/mongod.service << 'EOF'
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network.target

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --config /etc/mongod.conf
PIDFile=/var/run/mongodb/mongod.pid
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false

# Recommended limits for mongod as specified in
# https://docs.mongodb.com/manual/reference/ulimit/#recommended-ulimit-settings

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable mongod
    print_success "MongoDB systemd service created"
fi

# Create initialization script
cat > $APP_DIR/init.sh << 'EOF'
#!/bin/bash
# Initialization script for Ghana School MIS

cd /opt/school-mis

echo "Starting Ghana School MIS..."

# Start MongoDB
systemctl start mongod

# Start backend
cd backend
npm start &

# Start frontend
cd ../frontend
npm run build
serve -s dist -l 3000 &

echo "Application started successfully!"
echo "Frontend: http://localhost:3000"
echo "Backend API: http://localhost:5000"
echo "API Documentation: http://localhost:5000/api-docs"
EOF

chmod +x $APP_DIR/init.sh

# Create update script
cat > $APP_DIR/update.sh << 'EOF'
#!/bin/bash
# Update script for Ghana School MIS

cd /opt/school-mis

echo "Updating Ghana School MIS..."

# Stop services
pm2 stop all

# Update from git
git pull origin main

# Update dependencies
cd backend
npm install --production

cd ../frontend
npm install --production
npm run build

# Restart services
cd ..
pm2 restart all
pm2 save

echo "Update completed successfully!"
EOF

chmod +x $APP_DIR/update.sh

print_info "========================================="
print_success "Ghana School MIS Setup Complete!"
print_info "========================================="
echo ""
print_info "Next steps:"
echo "1. Edit backend/.env file with your configuration"
echo "2. Run: cd $APP_DIR && ./init.sh"
echo "3. Access the application at http://localhost"
echo ""
print_info "Configuration files:"
echo "  - Backend: $APP_DIR/backend/.env"
echo "  - Nginx: /etc/nginx/sites-available/school-mis"
echo ""
print_info "Management commands:"
echo "  - Start: pm2 start ecosystem.config.js"
echo "  - Stop: pm2 stop ecosystem.config.js"
echo "  - Logs: pm2 logs"
echo "  - Update: $APP_DIR/update.sh"
echo ""
print_info "Support:"
echo "  - Documentation: $APP_DIR/docs/"
echo "  - Email: support@schoolmis.edu.gh"
echo ""
print_info "========================================="
