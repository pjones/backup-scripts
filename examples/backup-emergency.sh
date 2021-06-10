#!/usr/bin/env bash

################################################################################
# Create a backup for an emergency.
#
# The backup destination is a removable, encrypted hard drive on a
# remote machine.
set -eu
set -o pipefail

################################################################################
BACKUP_HOST=frau.pmade.com
BACKUP_USER=sjones
BACKUP_PORT=22
BACKUP_DIR="/Volumes/Emergency"

################################################################################
sync() {
  local src=$1
  local dest=$2
  shift 2

  ssh -p"$BACKUP_PORT" \
    "${BACKUP_USER}@${BACKUP_HOST}" \
    mkdir -p "$BACKUP_DIR/$dest"

  rsync \
    --verbose \
    --recursive \
    --links \
    --safe-links \
    --times \
    --delete-before \
    --delete-excluded \
    --prune-empty-dirs \
    --human-readable \
    --exclude="lost+found" \
    --rsh="ssh -p$BACKUP_PORT" \
    "$@" \
    "${src}/" \
    "${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DIR}/$dest/"
}

################################################################################
cleanup() {
  if mountpoint --quiet "$HOME/.password-store.mnt"; then
    mount-encrypted-dev -u "$HOME/.password-store.mnt"
  fi
}
trap cleanup EXIT

################################################################################
# Passwords:
password-store-to-encrypted-image -M -p machines/hq.pmade.com/encrypted-disk-images
sync ~/.password-store.mnt/ Passwords

################################################################################
# Other directories:
sync /var/lib/media/home-videos Videos
sync /var/lib/media/music Music
sync ~/documents/books-papers Books
sync ~/documents/pictures/photos Photos
sync ~/documents/taxes/returns Taxes
