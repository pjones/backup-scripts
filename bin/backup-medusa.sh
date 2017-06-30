#! @bash@/bin/bash

################################################################################
export BACKUP_RDIFF_DIR=/mnt/backup/home
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}

################################################################################
# shellcheck source=lib/backup.sh
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
cd /home || exit 1

################################################################################
# FIXME: Automatically abort if BACKUP_RDIFF_DIR isn't mounted

################################################################################
exclude_start
exclude_sccs
exclude_log_directories

################################################################################
backup_via_rdiff
