#!/bin/bash

################################################################################
# Script to backup or restore PostgreSQL WAL archives:
#
#   https://www.postgresql.org/docs/9.1/continuous-archiving.html
set -e
set -u

################################################################################
export PATH=@pathextras@:$PATH

################################################################################
# Where to store or retrieve WAL archive files:
BACKUP_POSTGRESQL_WAL_DIR=${BACKUP_POSTGRESQL_WAL_DIR:-../archive}

################################################################################
# If this file exists, archives will be copied:
BACKUP_POSTGRESQL_IN_PROGRESS=${BACKUP_POSTGRESQL_IN_PROGRESS:-../backup-in-progress}

################################################################################
if [ $# -eq 3 ]; then
  >&2 echo "Usage: backup|restore archive path"
  exit 1
fi

################################################################################
# Backup a WAL file.
wal_backup() {
  local file=$1;
  local path=$2;
  local out="$BACKUP_POSTGRESQL_WAL_DIR/$file.xz"

  if [ ! -e "$BACKUP_POSTGRESQL_IN_PROGRESS" ]; then
    exit 0
  fi

  if [ -e "$out" ]; then
    >&2 echo "ERROR: WAL file already archived!"
    exit 1
  fi

  mkdir -p "$(dirname "$out")"
  pg_compresslog "$path" - | xz > "$out"
}

################################################################################
# Restore a WAL file:
wal_restore() {
  local file=$1
  local path=$2
  local archive="$BACKUP_POSTGRESQL_WAL_DIR/$file.xz"

  if [ ! -e "$archive" ]; then
    >&2 echo "ERROR: WAL file does not exist!"
    exit 1
  fi

  xz -d "$archive" - | pg_decompresslog - "$path"
}

################################################################################
case "$1" in
  backup)
    wal_backup "$2" "$3"
    ;;

  restore)
    wal_restore "$2" "$3"
    ;;

  *)
    >&2 echo "ERROR: $1 should be backup or restore"
    ;;
esac
