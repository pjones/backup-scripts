#!/bin/bash

################################################################################
# What ssh key to use for doing remote backups.
BACKUP_SSH_KEY=${BACKUP_SSH_KEY:-/run/keys/backup-ssh-key}
BACKUP_SSH_PORT=${BACKUP_SSH_PORT:-22}

################################################################################
# Number of old backups to keep.
BACKUP_RSYNC_KEEP_COUNT=${BACKUP_RSYNC_KEEP_COUNT:-14}

################################################################################
# Sync a directory using rsync.
#
#   $1: Origin directory (include trailing slash).
#   $2: Destination directory (include trailing slash).
sync_via_rsync() {
  if [ $# -ne 2 ]; then
    die "Usage: sync_via_rsync origin destination"
  fi

  local origin="$1";      shift
  local destination="$1"; shift

  log "syncing $origin -> $destination"
  rsync -au "$origin" "$destination"
}

################################################################################
# Backup a (remote) directory using rsync and hard links.
#
# The destination directory will be used as a base directory where
# per-backup directories are created as needed.
backup_via_rsync() {
  if [ $# -lt 2 ]; then
    die "Usage: backup_via_rsync origin destination"
  fi

  local origin=$1
  local destination=$2
  local last=$(_rsync_find_subdirs "$destination" | tail -1)
  local next="$destination/$(date +%Y-%m-%d_%H:%M:%S)"
  local ssh_options=("-p" "$BACKUP_SSH_PORT" "-i" "$BACKUP_SSH_KEY" "-oStrictHostKeyChecking=no")

  # Ensure origin ends with a slash:
  if ! echo "$origin" | grep -E '/$'; then
    origin="$origin"/
  fi

  if [ -e "$next" ]; then
    die "WTF? next dir $next already exists somehow!"
  fi

  if [ -e "$last" ]; then
    cp --recursive --link "$last" "$next"
  else
    mkdir -p "$next"
  fi

  log "backing up $origin to $next"
  rsync -aLkv -e "ssh ${ssh_options[*]}" "$origin" "$next"/
}

################################################################################
# Remove old backups.
prune_rsync_backup_directory() {
  local destination=$1
  local count
  local num_to_remove
  local to_remove

  count=$(_rsync_find_subdirs "$destination" | wc -l)

  if [ "$count" -gt "$BACKUP_RSYNC_KEEP_COUNT" ]; then
    num_to_remove=$((count - BACKUP_RSYNC_KEEP_COUNT))
    mapfile -t to_remove < <(_rsync_find_subdirs "$destination" | head --lines="$num_to_remove")
    rm -r "${to_remove[@]}"
  fi
}

################################################################################
# Returns all subdirectories of the given directory.
_rsync_find_subdirs() {
  local dir=$1; shift
  find "$dir" -mindepth 1 -maxdepth 1 -type d "$@" | sort
}
