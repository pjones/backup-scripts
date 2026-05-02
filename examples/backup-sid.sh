#!/usr/bin/env bash

################################################################################
# Backup documents that are not synced with Git.
set -eu
set -o pipefail

################################################################################
top="$(realpath "$(dirname "$0")/..")"
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-$top/lib}

################################################################################
# shellcheck source=../lib/backup.sh
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
locked_uuid=28761c11-f814-4078-864f-d0c5b97c79fb
unlocked_uuid=7c53dda6-d735-4601-906e-f3ffb282485e
mount_point=/run/media/$USER/$unlocked_uuid
remote_server="backup.sid"

################################################################################
local_directories=()

################################################################################
function report_local_dirs() {
  log "local directory sizes:"
  for dir in "${local_directories[@]}"; do
    du -hs "$dir"
  done

  log "drive status:"
  df -h --output=size,used,avail,pcent "$mount_point"
}

################################################################################
function remote_fetch() {
  local remote_dir=$1
  local local_dir=${2:-}

  if [[ -z ${local_dir:-} ]]; then
    local_dir=$(basename "$remote_dir")
  fi

  log "$remote_server:$(basename "$remote_dir")"
  local_dir="$mount_point/backup/$remote_server/$local_dir"
  local_directories+=("$local_dir")

  sync_latest_archive_via_rsync \
    "$remote_server" \
    "$remote_dir" \
    "$local_dir"

  "$top/bin/backup-purge.sh" -k 14 "$local_dir"
}

################################################################################
function main() {
  backup_mount_dir \
    -l "$locked_uuid" \
    "$unlocked_uuid" \
    "$mount_point"

  remote_fetch "/var/lib/backup/paperless" "paperless/files"
  remote_fetch "/var/lib/backup/postgresql/paperless" "paperless/db"
  remote_fetch "/var/lib/backup/postgresql/vaultwarden"

  # FIXME: fix the script to set correct ownership:
  # remote_fetch "/var/lib/backup/plex"

  report_local_dirs
}

################################################################################
main "$@"
