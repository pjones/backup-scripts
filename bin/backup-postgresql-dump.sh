#!/bin/bash

################################################################################
# Backup PostgreSQL via pg_dumpall.
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/var/lib/backup/postgres}
BACKUP_FILE_NAME="$(date +%Y-%m-%d_%H:%M:%S).xz"

################################################################################
DUMPALL_OPTIONS=${DUMPALL_OPTIONS:-"-o"}
DUMPONE_OPTIONS=${DUMPONE_OPTIONS:-"-Cbo"}
DUMP_CMD="pg_dumpall"

################################################################################
# When given a name of a database, dump only that database:
if [ $# -eq 1 ] && [ -n "$1" ]; then
  BACKUP_DIRECTORY="$BACKUP_DIRECTORY/$1"
  DUMP_CMD="pg_dump --dbname=$1"
  DUMP_ARGS=$DUMPONE_OPTIONS
else
  DUMP_ARGS=$DUMPALL_OPTIONS
fi

mkdir -p "$BACKUP_DIRECTORY"
su - postgres -c "$DUMP_CMD $DUMP_ARGS" | xz > "$BACKUP_DIRECTORY/_$BACKUP_FILE_NAME"
mv "$BACKUP_DIRECTORY/_$BACKUP_FILE_NAME" "$BACKUP_DIRECTORY/$BACKUP_FILE_NAME"
