#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
# What ssh key to use for doing remote backups.
BACKUP_SSH_KEY=${BACKUP_SSH_KEY:-/run/keys/backup-ssh-key}
BACKUP_SSH_PORT=${BACKUP_SSH_PORT:-22}

################################################################################
# Control whether we ignore "file vanished" errors.
BACKUP_RSYNC_IGNORE_VANISHED=${BACKUP_RSYNC_IGNORE_VANISHED:-1}

################################################################################
BACKUP_RSYNC_COMMON_ARGS=(
  "--archive"
  "--update"
  "--human-readable"
  "--progress"
)

################################################################################
# Sync a directory using rsync.
#
#   $1: Origin directory (include trailing slash).
#   $2: Destination directory (include trailing slash).
sync_via_rsync() {
  if [ $# -ne 2 ]; then
    die "Usage: sync_via_rsync origin destination"
  fi

  local origin="$1"
  shift
  local destination="$1"
  shift

  log "syncing $origin -> $destination"
  rsync "${BACKUP_RSYNC_COMMON_ARGS[@]}" "$origin" "$destination"
}

################################################################################
# Sync the latest backup archive from a remote server.
#
#  Usage: sync_latest_archive_via_rsync [options] server rdir ldir
#
#  server: The server name.
#    rdir: The remote directory
#    ldir: The local backup directory
#
# Options:
#
#  -u USER Connect as USER
#
function sync_latest_archive_via_rsync() {
  local server
  local remote_dir
  local local_dir
  local user

  OPTIND=1
  while getopts "hu:" o; do
    case "${o}" in
    u)
      user=$OPTARG
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [[ $# != 3 ]]; then
    echo >&2 "ERROR: sync_latest_archive_via_rsync: expected server ldir rdir"
    exit 1
  fi

  server=$1
  remote_dir=$2
  local_dir=$3

  local ssh_server=$server

  if [[ -n ${user:-} ]]; then
    ssh_server="${user}@${ssh_server}"
  fi

  # Get the latest file name from the server:
  local latest
  latest=$(ssh "$ssh_server" bash -s <<<"
    ls -t '$remote_dir' | head -n 1
  ")

  if [[ -n ${latest:-} ]]; then
    mkdir -p "$local_dir"
    rsync "${BACKUP_RSYNC_COMMON_ARGS[@]}" \
      "${ssh_server}:${remote_dir}/${latest}" \
      "$local_dir/$latest"
  fi
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
  shift 2

  local last
  local next

  local ssh_options=(
    "-p" "$BACKUP_SSH_PORT"
    "-i" "$BACKUP_SSH_KEY"
    "-oStrictHostKeyChecking=no"
  )

  local delete_options=(
    "--delete"
    "--delete-after"
    "--delete-excluded"
  )

  # The last backup that was taken.  Used for hard linking files that
  # haven't changed:
  last=$(
    find "$destination" -mindepth 1 -maxdepth 1 -type d |
      sort |
      tail -1
  )

  # The name of the backup directory to create:
  next="$destination/$(date +%Y-%m-%d_%H:%M:%S)"

  # Ensure origin ends with a slash:
  if ! echo "$origin" | grep -E '/$'; then
    origin="$origin"/
  fi

  if [ -e "$next" ]; then
    die "WTF? next dir $next already exists somehow!"
  fi

  if [ -e "$last" ]; then
    log "hard linking to previous backup: $last -> $next"
    cp --archive --link "$last" "$next"
  else
    log "no previous backup found, starting from scratch"
    mkdir -p "$next"
  fi

  log "backing up $origin to $next"

  if ! rsync \
    -aFv "${delete_options[@]}" \
    -e "ssh ${ssh_options[*]}" \
    "$@" "$origin" "$next"/; then

    status=$?

    if [ "$BACKUP_RSYNC_IGNORE_VANISHED" -eq 1 ] && [ "$status" -eq 24 ]; then
      status=0
    fi

    if [ "$status" -ne 0 ]; then
      exit "$status"
    fi
  fi

  log "updating 'latest' symlink"
  (
    cd "$destination" &&
      ln -nfs "$(basename "$next")" latest
  )
}
