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
  --exclude=.cache \
  --exclude=archive \
  --exclude=download \
  --exclude=git \
  --exclude=sync \
  ./ "$destination":/home/pjones/

################################################################################
# Sync over my archive drive:
change_directory /var/lib/backup

rsync \
  -avu \
  --delete \
  --exclude=lost+found \
  archive/ "$destination":archive/
