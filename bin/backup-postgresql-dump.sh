#!/bin/bash

################################################################################
# Backup PostgreSQL via pg_dumpall.
set -e
set -u

################################################################################
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/var/lib/backup/postgres}
BACKUP_FILE_NAME="$(date +%Y-%m-%d_%H:%M:%S).xz"

################################################################################
mkdir -p "$BACKUP_DIRECTORY"
su postgres -c 'pg_dumpall' | xz > "$BACKUP_DIRECTORY/_$BACKUP_FILE_NAME"
mv "$BACKUP_DIRECTORY/_$BACKUP_FILE_NAME" "$BACKUP_DIRECTORY/$BACKUP_FILE_NAME"
