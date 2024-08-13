#!/usr/bin/env bash

################################################################################
# Clone data on Medusa to an external drive.
set -eu
set -o pipefail

################################################################################
dest_disk=/dev/disk/by-uuid/4ca5f766-afa3-44b2-a535-ff01b633cdf3
mount_point=$HOME/mnt/backup
pass_entry=machines/hq.pmade.com/home-backup-drive

################################################################################
cleanup() {
  if [ -e "$mount_point" ]; then
    if mountpoint --quiet "$mount_point"; then
      mount-encrypted-dev -u "$mount_point"
    fi
  fi
}

################################################################################
sync() {
  local from=$1
  local to=$2

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
    "$from" "$to"

}

################################################################################
main() {
  trap cleanup EXIT

  mkdir -p "$mount_point"

  mount-encrypted-dev \
    -p "$pass_entry" \
    "$dest_disk" "$mount_point"

  sudo mkdir -p "$mount_point/home" "$mount_point/archive"
  sudo chown pjones:pjones "$mount_point/home" "$mount_point/archive"
  sync ~/ "$mount_point/home/"
  sync /var/lib/backup/archive "$mount_point/archive/"
}

################################################################################
main "$@"
