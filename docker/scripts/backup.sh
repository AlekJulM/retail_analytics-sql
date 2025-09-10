#!/bin/bash

# Retail Analytics Database Backup Script
# Usage: docker-compose exec mysql_backup /scripts/backup.sh

set -e

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
DB_NAME="retail_analytics"
BACKUP_FILE="${BACKUP_DIR}/retail_analytics_backup_${TIMESTAMP}.sql"

echo "Starting backup of ${DB_NAME} database..."

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Perform the backup
mysqldump -h mysql -u retail_user -pretail_password_2024 \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --hex-blob \
  --complete-insert \
  --add-drop-database \
  --databases ${DB_NAME} > ${BACKUP_FILE}

# Compress the backup
gzip ${BACKUP_FILE}

echo "Backup completed: ${BACKUP_FILE}.gz"

# Clean up old backups (keep last 7 days)
find ${BACKUP_DIR} -name "retail_analytics_backup_*.sql.gz" -mtime +7 -delete

echo "Old backups cleaned up (kept last 7 days)"

# Display backup file size
ls -lh ${BACKUP_FILE}.gz

echo "Backup process completed successfully"
