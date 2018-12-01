#!/bin/bash

################################################################################
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
# Back up all home directories:
change_directory /home
backup_to_mount_point /mnt/backup/home
exclude_start
exclude_sccs
exclude_log_directories
backup_via_rdiff

################################################################################
# Back up music and other media files:
change_directory /var/media/content/music
backup_to_directory /mnt/backup/misc/music
exclude_nothing
backup_via_rdiff

################################################################################
# System files:
change_directory /var/lib/backup
backup_to_directory /mnt/backup/misc/var.lib.backup
exclude_nothing
backup_via_rdiff
