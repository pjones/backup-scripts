#!/bin/bash

################################################################################
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-@libdir@}
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
destination=kilgrave.pmade.com

################################################################################
# Sync over ~/
change_directory "$HOME"

rsync \
  -avu \
  --delete \
  --exclude=/.cache/ \
  --exclude=/download/ \
  --exclude=/src/ \
  --exclude=/documents/ripping/ \
  --exclude=/documents/disk-images/ \
  ./ "$destination":/home/pjones/backup/

################################################################################
# Sync over my archive drive:
change_directory /var/lib/backup

rsync \
  -avu \
  --delete \
  --exclude=lost+found \
  archive/ "$destination":archive/
