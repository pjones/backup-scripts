#!/bin/bash

################################################################################
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
# Backup remote machines:
for machine in kilgrave ursula moriarty; do
  mkdir -p /home/backup/"$machine"
  change_directory /home/backup/"$machine"
  backup_via_rsync root@"$machine".pmade.com:/var/lib/backup .
  prune_rsync_backup_directory .
done
