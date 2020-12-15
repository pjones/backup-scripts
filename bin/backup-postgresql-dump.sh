#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
# Backup PostgreSQL via pg_dumpall.
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}

################################################################################
# shellcheck source=../lib/backup.sh
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/var/lib/backup/postgres}
BACKUP_FILE_NAME="$(date +%Y-%m-%d_%H:%M:%S).xz"

################################################################################
DUMPALL_OPTIONS=${DUMPALL_OPTIONS:-"-o"}
DUMPONE_OPTIONS=${DUMPONE_OPTIONS:-"-cCb"}

################################################################################
command="pg_dumpall"
args=()

################################################################################
# When given a name of a database, dump only that database:
if [ $# -eq 1 ] && [ -n "$1" ]; then
  BACKUP_DIRECTORY="$BACKUP_DIRECTORY/$1"
  command="pg_dump"
  args+=("--dbname=$1")
  args+=("$DUMPONE_OPTIONS")
else
  args+=("$DUMPALL_OPTIONS")
fi

if [ ! -e "$BACKUP_DIRECTORY" ]; then
  mkdir -p "$BACKUP_DIRECTORY"
fi

log "PostgreSQL backup: $command ${args[*]}"
"$command" "${args[@]}" | xz >"$BACKUP_DIRECTORY/_$BACKUP_FILE_NAME"
mv "$BACKUP_DIRECTORY/_$BACKUP_FILE_NAME" "$BACKUP_DIRECTORY/$BACKUP_FILE_NAME"
