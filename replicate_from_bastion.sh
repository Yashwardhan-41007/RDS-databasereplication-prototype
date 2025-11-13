#!/bin/bash
# RDS Replication Script - Run this on your bastion host
# Usage: ./replicate_from_bastion.sh

set -euo pipefail

# Prompt for credentials
read -p "Database name: " DB_NAME
read -p "Source RDS host: " SRC_HOST
read -p "Source RDS user: " SRC_USER
read -sp "Source RDS password: " SRC_PASS
echo ""
read -p "Target RDS host: " TGT_HOST
read -p "Target RDS user: " TGT_USER
read -sp "Target RDS password: " TGT_PASS
echo ""

echo "🔄 Starting replication of database: $DB_NAME"
echo "Source: $SRC_HOST"
echo "Target: $TGT_HOST"
echo ""

# Test source connection
echo "Testing source RDS connection..."
export MYSQL_PWD="$SRC_PASS"
if mysql -h "$SRC_HOST" -u "$SRC_USER" -e "SELECT 1" > /dev/null 2>&1; then
    echo "✅ Source connection OK"
else
    echo "❌ Source connection failed"
    exit 1
fi

# Test target connection
echo "Testing target RDS connection..."
export MYSQL_PWD="$TGT_PASS"
if mysql -h "$TGT_HOST" -u "$TGT_USER" -e "SELECT 1" > /dev/null 2>&1; then
    echo "✅ Target connection OK"
else
    echo "❌ Target connection failed"
    exit 1
fi

# Perform replication
echo ""
echo "🔄 Starting database dump and restore..."
export MYSQL_PWD="$SRC_PASS"
mysqldump -h "$SRC_HOST" \
          -u "$SRC_USER" \
          --single-transaction \
          --quick \
          --routines \
          --triggers \
          --events \
          --set-gtid-purged=OFF \
          --databases "$DB_NAME" 2>/dev/null | \
MYSQL_PWD="$TGT_PASS" mysql -h "$TGT_HOST" -u "$TGT_USER" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Replication completed successfully!"
else
    echo "❌ Replication failed"
    exit 1
fi

# Verify replication
echo ""
echo "🔍 Verifying replication..."
export MYSQL_PWD="$SRC_PASS"
SRC_TABLES=$(mysql -h "$SRC_HOST" -u "$SRC_USER" -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB_NAME'" 2>/dev/null)

export MYSQL_PWD="$TGT_PASS"
TGT_TABLES=$(mysql -h "$TGT_HOST" -u "$TGT_USER" -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB_NAME'" 2>/dev/null)

echo "Source tables: $SRC_TABLES"
echo "Target tables: $TGT_TABLES"

if [ "$SRC_TABLES" -eq "$TGT_TABLES" ]; then
    echo "✅ Verification passed - Table counts match!"
else
    echo "⚠️  Warning: Table count mismatch"
    exit 1
fi

echo ""
echo "🎉 All done!"
