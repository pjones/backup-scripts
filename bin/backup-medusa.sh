#! @bash@/bin/bash

################################################################################
export BACKUP_RDIFF_DIR=/mnt/backup/home
export BACKUP_LOG_DIR=/var/lib/backup/log
export BACKUP_EXCLUDE_DIR=/var/lib/backup/exclude

################################################################################
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
cd /home || exit 1

################################################################################
exclude_start
exclude_sccs
exclude_log_directories

################################################################################
backup_via_rdiff
