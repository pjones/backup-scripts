#! @bash@/bin/bash

################################################################################
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}
export BACKUP_LOG_DIR=${HOME}/backup/log
export BACKUP_SYNC_DIR=${HOME}/backup/moriarty

################################################################################
# shellcheck source=lib/backup.sh
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
cd "$BACKUP_SYNC_DIR" || die "$BACKUP_SYNC_DIR is missing"
sync_via_rsync moriarty.pmade.com:git/  git/
sync_via_rsync moriarty.pmade.com:mail/ mail/
