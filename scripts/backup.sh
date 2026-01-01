#!/bin/bash

# Ghana School MIS Backup Script
# Automatically backs up database and application files

# Configuration
BACKUP_DIR="/opt/school-mis/backups"
LOG_DIR="/opt/school-mis/logs"
APP_DIR="/opt/school-mis"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="school-mis-backup-$DATE"
MAX_BACKUPS=30  # Keep last 30 backups

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_DIR/backup.log"
}

log_success() {
    log "${GREEN}[SUCCESS] $1${NC}"
}

log_error() {
    log "${RED}[ERROR] $1${NC}"
}

log_warning() {
    log "${YELLOW}[WARNING] $1${NC}"
}

# Create directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Start backup
log "Starting Ghana School MIS backup..."

# Backup MongoDB
backup_mongodb() {
    if command -v mongodump &> /dev/null; then
        log "Backing up MongoDB..."
        
        # Get MongoDB connection details from environment
        if [ -f "$APP_DIR/backend/.env" ]; then
            source "$APP_DIR/backend/.env"
            MONGODB_URI=${MONGODB_URI:-"mongodb://localhost:27017/school_mis"}
        else
            MONGODB_URI="mongodb://localhost:27017/school_mis"
        fi
        
        # Extract credentials from URI
        if [[ $MONGODB_URI == mongodb://*@* ]]; then
            # URI with credentials
            USER_PASS=$(echo "$MONGODB_URI" | sed -n 's/mongodb:\/\/\(.*\)@.*/\1/p')
            HOST_DB=$(echo "$MONGODB_URI" | sed -n 's/mongodb:\/\/.*@\(.*\)/\1/p')
            USERNAME=$(echo "$USER_PASS" | cut -d: -f1)
            PASSWORD=$(echo "$USER_PASS" | cut -d: -f2)
            HOST=$(echo "$HOST_DB" | cut -d/ -f1)
            DATABASE=$(echo "$HOST_DB" | cut -d/ -f2)
            
            # Run mongodump with authentication
            if mongodump --host "$HOST" --username "$USERNAME" --password "$PASSWORD" --db "$DATABASE" --out "$BACKUP_DIR/$BACKUP_NAME/mongodb" --quiet; then
                log_success "MongoDB backup completed"
            else
                log_error "MongoDB backup failed"
                return 1
            fi
        else
            # URI without credentials
            HOST_DB=$(echo "$MONGODB_URI" | sed 's/mongodb:\/\///')
            HOST=$(echo "$HOST_DB" | cut -d/ -f1)
            DATABASE=$(echo "$HOST_DB" | cut -d/ -f2)
            
            if mongodump --host "$HOST" --db "$DATABASE" --out "$BACKUP_DIR/$BACKUP_NAME/mongodb" --quiet; then
                log_success "MongoDB backup completed"
            else
                log_error "MongoDB backup failed"
                return 1
            fi
        fi
    else
        log_warning "mongodump not found, skipping MongoDB backup"
    fi
    return 0
}

# Backup MySQL
backup_mysql() {
    if command -v mysqldump &> /dev/null; then
        log "Backing up MySQL..."
        
        # Get MySQL credentials from environment
        MYSQL_USER="root"
        MYSQL_PASSWORD=""
        
        if [ -f "$APP_DIR/backend/.env" ]; then
            source "$APP_DIR/backend/.env"
            MYSQL_USER=${DB_USER:-"root"}
            MYSQL_PASSWORD=${DB_PASSWORD:-""}
        fi
        
        # Backup all databases
        if [ -n "$MYSQL_PASSWORD" ]; then
            if mysqldump --all-databases --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --single-transaction --quick > "$BACKUP_DIR/$BACKUP_NAME/mysql.sql"; then
                log_success "MySQL backup completed"
            else
                log_error "MySQL backup failed"
                return 1
            fi
        else
            if mysqldump --all-databases --user="$MYSQL_USER" --single-transaction --quick > "$BACKUP_DIR/$BACKUP_NAME/mysql.sql"; then
                log_success "MySQL backup completed"
            else
                log_error "MySQL backup failed"
                return 1
            fi
        fi
        
        # Compress the SQL file
        gzip "$BACKUP_DIR/$BACKUP_NAME/mysql.sql"
    else
        log_warning "mysqldump not found, skipping MySQL backup"
    fi
    return 0
}

# Backup PostgreSQL
backup_postgresql() {
    if command -v pg_dumpall &> /dev/null; then
        log "Backing up PostgreSQL..."
        
        # Get PostgreSQL credentials from environment
        if [ -f "$APP_DIR/backend/.env" ]; then
            source "$APP_DIR/backend/.env"
            PG_USER=${PG_USER:-"postgres"}
            PG_PASSWORD=${PG_PASSWORD:-""}
        else
            PG_USER="postgres"
            PG_PASSWORD=""
        fi
        
        # Set password for pg_dumpall
        export PGPASSWORD="$PG_PASSWORD"
        
        if pg_dumpall --username="$PG_USER" --file="$BACKUP_DIR/$BACKUP_NAME/postgresql.sql"; then
            log_success "PostgreSQL backup completed"
            gzip "$BACKUP_DIR/$BACKUP_NAME/postgresql.sql"
        else
            log_error "PostgreSQL backup failed"
            return 1
        fi
        
        unset PGPASSWORD
    else
        log_warning "pg_dumpall not found, skipping PostgreSQL backup"
    fi
    return 0
}

# Backup application files
backup_application() {
    log "Backing up application files..."
    
    # Backup uploads directory
    if [ -d "$APP_DIR/backend/uploads" ]; then
        cp -r "$APP_DIR/backend/uploads" "$BACKUP_DIR/$BACKUP_NAME/"
        log_success "Uploads directory backed up"
    fi
    
    # Backup environment files
    if [ -f "$APP_DIR/backend/.env" ]; then
        cp "$APP_DIR/backend/.env" "$BACKUP_DIR/$BACKUP_NAME/"
        log_success "Environment file backed up"
    fi
    
    # Backup important configuration files
    if [ -f "$APP_DIR/docker-compose.yml" ]; then
        cp "$APP_DIR/docker-compose.yml" "$BACKUP_DIR/$BACKUP_NAME/"
    fi
    
    if [ -f "$APP_DIR/ecosystem.config.js" ]; then
        cp "$APP_DIR/ecosystem.config.js" "$BACKUP_DIR/$BACKUP_NAME/"
    fi
    
    # Backup database schema
    if [ -f "$APP_DIR/database/init.sql" ]; then
        cp "$APP_DIR/database/init.sql" "$BACKUP_DIR/$BACKUP_NAME/"
    fi
    
    log_success "Application files backup completed"
    return 0
}

# Create archive
create_archive() {
    log "Creating backup archive..."
    
    # Calculate size before compression
    SIZE_BEFORE=$(du -sb "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
    
    # Create compressed archive
    if tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME"; then
        # Calculate size after compression
        SIZE_AFTER=$(stat -c%s "$BACKUP_DIR/$BACKUP_NAME.tar.gz")
        COMPRESSION_RATIO=$(echo "scale=2; (1 - $SIZE_AFTER/$SIZE_BEFORE) * 100" | bc)
        
        log_success "Archive created: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
        log "Compression ratio: ${COMPRESSION_RATIO}%"
        log "Archive size: $(numfmt --to=iec-i --suffix=B $SIZE_AFTER)"
    else
        log_error "Failed to create archive"
        return 1
    fi
    
    # Clean up temporary directory
    rm -rf "$BACKUP_DIR/$BACKUP_NAME"
    
    return 0
}

# Clean old backups
clean_old_backups() {
    log "Cleaning old backups..."
    
    # Count current backups
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f | wc -l)
    
    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        # Delete oldest backups
        TO_DELETE=$((BACKUP_COUNT - MAX_BACKUPS))
        log "Removing $TO_DELETE old backup(s)"
        
        find "$BACKUP_DIR" -name "*.tar.gz" -type f -printf '%T@ %p\n' | \
            sort -n | \
            head -n "$TO_DELETE" | \
            cut -d' ' -f2- | \
            xargs rm -f
        
        log_success "Old backups cleaned"
    else
        log "No old backups to clean (keeping $BACKUP_COUNT of $MAX_BACKUPS maximum)"
    fi
}

# Verify backup integrity
verify_backup() {
    log "Verifying backup integrity..."
    
    if [ -f "$BACKUP_DIR/$BACKUP_NAME.tar.gz" ]; then
        # Test archive integrity
        if tar -tzf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" > /dev/null 2>&1; then
            log_success "Backup integrity verified"
            
            # Calculate checksum
            CHECKSUM=$(sha256sum "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -d' ' -f1)
            echo "$CHECKSUM $BACKUP_NAME.tar.gz" > "$BACKUP_DIR/$BACKUP_NAME.tar.gz.sha256"
            
            log "SHA256 checksum: $CHECKSUM"
            return 0
        else
            log_error "Backup integrity check failed"
            return 1
        fi
    else
        log_error "Backup file not found"
        return 1
    fi
}

# Main backup function
main_backup() {
    local start_time=$(date +%s)
    local errors=0
    
    log "========================================"
    log "Starting Ghana School MIS Backup"
    log "Date: $(date)"
    log "Backup name: $BACKUP_NAME"
    log "========================================"
    
    # Run backup functions
    backup_mongodb || ((errors++))
    backup_mysql || ((errors++))
    backup_postgresql || ((errors++))
    backup_application || ((errors++))
    
    if [ $errors -eq 0 ]; then
        create_archive || ((errors++))
        verify_backup || ((errors++))
        clean_old_backups
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log "========================================"
        log_success "Backup completed successfully!"
        log "Duration: ${duration} seconds"
        log "Backup location: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
        log "========================================"
        
        # Send notification (if configured)
        send_notification "success" "Backup completed successfully in ${duration}s"
        
        return 0
    else
        log "========================================"
        log_error "Backup completed with $errors error(s)"
        log "========================================"
        
        # Send notification (if configured)
        send_notification "error" "Backup completed with $errors error(s)"
        
        return 1
    fi
}

# Send notification (email, Slack, etc.)
send_notification() {
    local status="$1"
    local message="$2"
    
    # Check if notifications are enabled
    if [ -f "$APP_DIR/backend/.env" ]; then
        source "$APP_DIR/backend/.env"
        
        # Email notification
        if [ "$BACKUP_NOTIFY_EMAIL" = "true" ] && [ -n "$SMTP_USER" ]; then
            send_email_notification "$status" "$message"
        fi
        
        # Slack notification
        if [ "$BACKUP_NOTIFY_SLACK" = "true" ] && [ -n "$SLACK_WEBHOOK_URL" ]; then
            send_slack_notification "$status" "$message"
        fi
    fi
}

send_email_notification() {
    local status="$1"
    local message="$2"
    local subject="Ghana School MIS Backup - $status"
    
    # Create email content
    local email_content="
Subject: $subject
From: $SMTP_USER
To: $ADMIN_EMAIL

Ghana School MIS Backup Report
==============================
Status: $status
Time: $(date)
Backup: $BACKUP_NAME
Message: $message

Backup Location: $BACKUP_DIR/$BACKUP_NAME.tar.gz
Size: $(stat -c%s "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | numfmt --to=iec-i --suffix=B)

Recent Backups:
$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -printf "%Tb %Td %TH:%TM %p\n" | sort -r | head -5)

System Information:
- Hostname: $(hostname)
- Disk Usage: $(df -h / | tail -1)
- Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')
    "
    
    # Send email using sendmail or similar
    echo "$email_content" | sendmail -t 2>/dev/null || true
}

send_slack_notification() {
    local status="$1"
    local message="$2"
    local color="good"
    
    if [ "$status" = "error" ]; then
        color="danger"
    fi
    
    local slack_payload="{
        \"attachments\": [
            {
                \"color\": \"$color\",
                \"title\": \"Ghana School MIS Backup - $status\",
                \"text\": \"$message\",
                \"fields\": [
                    {
                        \"title\": \"Backup Name\",
                        \"value\": \"$BACKUP_NAME\",
                        \"short\": true
                    },
                    {
                        \"title\": \"Time\",
                        \"value\": \"$(date)\",
                        \"short\": true
                    },
                    {
                        \"title\": \"Location\",
                        \"value\": \"$BACKUP_DIR/$BACKUP_NAME.tar.gz\",
                        \"short\": false
                    }
                ],
                \"footer\": \"School MIS Backup System\",
                \"ts\": $(date +%s)
            }
        ]
    }"
    
    curl -X POST -H 'Content-type: application/json' \
         --data "$slack_payload" \
         "$SLACK_WEBHOOK_URL" > /dev/null 2>&1 || true
}

# Create restore script
create_restore_script() {
    log "Creating restore script..."
    
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# Ghana School MIS Restore Script

BACKUP_DIR="/opt/school-mis/backups"
APP_DIR="/opt/school-mis"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    log "${GREEN}[SUCCESS] $1${NC}"
}

log_error() {
    log "${RED}[ERROR] $1${NC}"
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Restore Ghana School MIS from backup"
    echo
    echo "Options:"
    echo "  -b, --backup FILE    Specify backup file to restore"
    echo "  -l, --list           List available backups"
    echo "  -h, --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --list"
    echo "  $0 --backup school-mis-backup-20240101_120000.tar.gz"
    echo
}

list_backups() {
    echo "Available backups:"
    echo "=================="
    find "$BACKUP_DIR" -name "*.tar.gz" -type f -printf "%Tb %Td %TH:%TM | %p\n" | sort -r
    echo
}

verify_backup() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    # Check if backup is valid tar.gz
    if ! tar -tzf "$backup_file" > /dev/null 2>&1; then
        log_error "Invalid backup file: $backup_file"
        return 1
    fi
    
    # Verify checksum if exists
    local checksum_file="$backup_file.sha256"
    if [ -f "$checksum_file" ]; then
        if sha256sum -c "$checksum_file" > /dev/null 2>&1; then
            log_success "Backup checksum verified"
        else
            log_error "Backup checksum verification failed"
            return 1
        fi
    fi
    
    return 0
}

extract_backup() {
    local backup_file="$1"
    local temp_dir="/tmp/school-mis-restore-$(date +%s)"
    
    mkdir -p "$temp_dir"
    
    log "Extracting backup..."
    if tar -xzf "$backup_file" -C "$temp_dir"; then
        log_success "Backup extracted to $temp_dir"
        echo "$temp_dir"
    else
        log_error "Failed to extract backup"
        rm -rf "$temp_dir"
        return 1
    fi
}

restore_mongodb() {
    local backup_path="$1"
    
    if [ -d "$backup_path/mongodb" ]; then
        log "Restoring MongoDB..."
        
        # Get MongoDB connection details
        if [ -f "$APP_DIR/backend/.env" ]; then
            source "$APP_DIR/backend/.env"
            MONGODB_URI=${MONGODB_URI:-"mongodb://localhost:27017/school_mis"}
        else
            MONGODB_URI="mongodb://localhost:27017/school_mis"
        fi
        
        # Extract credentials from URI
        if [[ $MONGODB_URI == mongodb://*@* ]]; then
            USER_PASS=$(echo "$MONGODB_URI" | sed -n 's/mongodb:\/\/\(.*\)@.*/\1/p')
            HOST_DB=$(echo "$MONGODB_URI" | sed -n 's/mongodb:\/\/.*@\(.*\)/\1/p')
            USERNAME=$(echo "$USER_PASS" | cut -d: -f1)
            PASSWORD=$(echo "$USER_PASS" | cut -d: -f2)
            HOST=$(echo "$HOST_DB" | cut -d/ -f1)
            DATABASE=$(echo "$HOST_DB" | cut -d/ -f2)
            
            if mongorestore --host "$HOST" --username "$USERNAME" --password "$PASSWORD" --db "$DATABASE" "$backup_path/mongodb" --drop; then
                log_success "MongoDB restored successfully"
            else
                log_error "MongoDB restore failed"
                return 1
            fi
        else
            HOST_DB=$(echo "$MONGODB_URI" | sed 's/mongodb:\/\///')
            HOST=$(echo "$HOST_DB" | cut -d/ -f1)
            DATABASE=$(echo "$HOST_DB" | cut -d/ -f2)
            
            if mongorestore --host "$HOST" --db "$DATABASE" "$backup_path/mongodb" --drop; then
                log_success "MongoDB restored successfully"
            else
                log_error "MongoDB restore failed"
                return 1
            fi
        fi
    fi
    return 0
}

restore_mysql() {
    local backup_path="$1"
    
    if [ -f "$backup_path/mysql.sql.gz" ]; then
        log "Restoring MySQL..."
        
        # Get MySQL credentials
        MYSQL_USER="root"
        MYSQL_PASSWORD=""
        
        if [ -f "$APP_DIR/backend/.env" ]; then
            source "$APP_DIR/backend/.env"
            MYSQL_USER=${DB_USER:-"root"}
            MYSQL_PASSWORD=${DB_PASSWORD:-""}
        fi
        
        # Decompress and restore
        gunzip -c "$backup_path/mysql.sql.gz" | mysql --user="$MYSQL_USER" --password="$MYSQL_PASSWORD"
        
        if [ $? -eq 0 ]; then
            log_success "MySQL restored successfully"
        else
            log_error "MySQL restore failed"
            return 1
        fi
    fi
    return 0
}

restore_files() {
    local backup_path="$1"
    
    log "Restoring application files..."
    
    # Restore uploads
    if [ -d "$backup_path/uploads" ]; then
        rm -rf "$APP_DIR/backend/uploads"
        cp -r "$backup_path/uploads" "$APP_DIR/backend/"
        log_success "Uploads directory restored"
    fi
    
    # Restore environment file (backup first)
    if [ -f "$backup_path/.env" ]; then
        if [ -f "$APP_DIR/backend/.env" ]; then
            cp "$APP_DIR/backend/.env" "$APP_DIR/backend/.env.backup.$(date +%s)"
        fi
        cp "$backup_path/.env" "$APP_DIR/backend/"
        log_success "Environment file restored (old file backed up)"
    fi
    
    return 0
}

restore_backup() {
    local backup_file="$1"
    
    log "========================================"
    log "Starting Ghana School MIS Restore"
    log "Backup: $backup_file"
    log "Time: $(date)"
    log "========================================"
    
    # Verify backup
    if ! verify_backup "$backup_file"; then
        return 1
    fi
    
    # Ask for confirmation
    read -p "Are you sure you want to restore from this backup? This will overwrite existing data. (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Restore cancelled"
        return 0
    fi
    
    # Extract backup
    local backup_path=$(extract_backup "$backup_file")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Stop application
    log "Stopping application..."
    cd "$APP_DIR"
    pm2 stop all 2>/dev/null || true
    
    # Restore components
    local errors=0
    restore_mongodb "$backup_path" || ((errors++))
    restore_mysql "$backup_path" || ((errors++))
    restore_files "$backup_path" || ((errors++))
    
    # Clean up
    rm -rf "$backup_path"
    
    # Start application
    log "Starting application..."
    pm2 start all
    
    if [ $errors -eq 0 ]; then
        log "========================================"
        log_success "Restore completed successfully!"
        log "========================================"
        return 0
    else
        log "========================================"
        log_error "Restore completed with $errors error(s)"
        log "========================================"
        return 1
    fi
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--backup)
                BACKUP_FILE="$BACKUP_DIR/$2"
                shift 2
                ;;
            -l|--list)
                list_backups
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # If no backup specified, show list
    if [ -z "$BACKUP_FILE" ]; then
        list_backups
        read -p "Enter backup file name to restore: " BACKUP_FILE
        BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    fi
    
    # Run restore
    restore_backup "$BACKUP_FILE"
}

# Run main function
main "$@"
EOF
    
    chmod +x "$BACKUP_DIR/restore.sh"
    log_success "Restore script created: $BACKUP_DIR/restore.sh"
}

# Main execution
if [ "$1" = "--setup" ]; then
    # Initial setup mode
    log "Setting up backup system..."
    create_restore_script
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "backup.sh"; echo "0 2 * * * $APP_DIR/scripts/backup.sh >> $LOG_DIR/backup.log 2>&1") | crontab -
    
    log_success "Backup system setup complete"
    log "Backups will run daily at 2 AM"
    log "Use $BACKUP_DIR/restore.sh to restore from backup"
else
    # Normal backup mode
    main_backup
fi
