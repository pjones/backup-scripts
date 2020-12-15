#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}

################################################################################
# shellcheck source=../lib/backup.sh
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
export BACKUP_DEST_DIR=${BACKUP_DEST_DIR:-/mnt/backup/misc/remotes}

################################################################################
# Backup remote machines:
for machine in "$@"; do
  mkdir -p "$BACKUP_DEST_DIR/$machine"
  change_directory "$BACKUP_DEST_DIR/$machine"
  backup_via_rsync root@"$machine".pmade.com:/var/lib/backup .
  backup-purge.sh -k 14 -d .
done
