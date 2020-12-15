#!/usr/bin/env bash

################################################################################
# Backup a PostgreSQL database using "Standalone Hot Backups".
set -eu
set -o pipefail

################################################################################
if [ $# -ne 1 ]; then
  echo >&2 "Usage: $0 postgresql-directory"
  exit 1
fi

################################################################################
BACKUP_POSTGRESQL_DIR=$1
BACKUP_DEST_DIR=/var/lib/backup/postgres
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_INITIAL_NAME="$BACKUP_POSTGRESQL_DIR/$BACKUP_DATE.tar"

################################################################################
# Where to store or retrieve WAL archive files:
BACKUP_POSTGRESQL_WAL_DIR=${BACKUP_POSTGRESQL_WAL_DIR:-archive}

################################################################################
# If this file exists, archives will be copied:
BACKUP_POSTGRESQL_IN_PROGRESS=${BACKUP_POSTGRESQL_IN_PROGRESS:-backup-in-progress}

################################################################################
cleanup() {
  rm "${BACKUP_POSTGRESQL_DIR:?}/$BACKUP_POSTGRESQL_IN_PROGRESS"
  rm -rf "${BACKUP_POSTGRESQL_DIR:?}/$BACKUP_POSTGRESQL_WAL_DIR"
}

trap cleanup EXIT

################################################################################
touch "${BACKUP_POSTGRESQL_DIR:?}/$BACKUP_POSTGRESQL_IN_PROGRESS"
su postgres -c "mkdir -p ${BACKUP_POSTGRESQL_DIR:?}/$BACKUP_POSTGRESQL_WAL_DIR"
su postgres -c "psql -c \"select pg_start_backup('$BACKUP_DATE', false, false);\""

# Don't allow anything to fail until telling postgres the backup is done.
(
  set +e
  cd "$BACKUP_POSTGRESQL_DIR"
  tar -cf "$BACKUP_INITIAL_NAME" data
) || :

# Now we can fail again.
su postgres -c "psql -c 'select pg_stop_backup();'"

if [ ! -e "$BACKUP_INITIAL_NAME" ]; then
  echo >&2 "ERROR: tar did not create a backup!"
  exit 1
fi

tar -C "$BACKUP_POSTGRESQL_DIR" -rf "$BACKUP_INITIAL_NAME" "$BACKUP_POSTGRESQL_WAL_DIR"
xz "$BACKUP_INITIAL_NAME"
mkdir -p "$BACKUP_DEST_DIR"
mv "$BACKUP_INITIAL_NAME.xz" "$BACKUP_DEST_DIR"/
