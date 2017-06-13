#! @bash@/bin/bash

################################################################################
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}
. $BACKUP_LIB_DIR/backup.sh

################################################################################
cd $HOME

################################################################################
exclude_start
exclude_sccs
exclude_log_directories
