#! @bash@/bin/bash

################################################################################
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
# Back up all home directories:
change_directory /home
backup_to_directory /mnt/backup/home
exclude_start
exclude_sccs
exclude_log_directories
backup_via_rdiff

################################################################################
# Back up music and other media files:
change_directory /var/media/music
backup_to_directory /mnt/backup/misc/music
exclude_nothing
backup_via_rdiff
