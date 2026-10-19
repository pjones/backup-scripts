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
locked_uuid=4da1879b-efd6-45fc-bd76-b2170008f839
unlocked_uuid=e549177c-0e84-4e12-be3f-a28b1476fc47
mount_point=/run/media/pjones/$unlocked_uuid

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -k      Keep the disk mounted after the backup
  -h      This message

EOF
}

################################################################################
do_sync() {
  local from=$1
  local to=$2
  shift 2

  mkdir \
    --parents \
    "$mount_point/$to"

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
    --filter="- lost+found" \
    --filter="- .direnv" \
    --filter="- result" \
    "$@" "$from/" "$mount_point/$to/"
}

################################################################################
do_backup() {
  local from=$1
  local to=$2
  shift 2

  mkdir --parents "$mount_point/$to"
  backup_via_rsync "$from/" "$mount_point/$to/" "$@"
}

################################################################################
function slugworth_fetch() {
  local remote_dir=$1
  local local_dir=${2:-}
  local remote_server="backup.slugworth"

  if [[ -z ${local_dir:-} ]]; then
    local_dir=$(basename "$remote_dir")
  fi

  log "$remote_server:$(basename "$remote_dir")"
  local_dir="$mount_point/$remote_server/$local_dir"
  local_directories+=("$local_dir")

  sync_latest_archive_via_rsync \
    "$remote_server" \
    "$remote_dir" \
    "$local_dir"

  # Make sure at least one new file was downloaded:
  if [ "$(find "$local_dir" -mtime -1 -print | wc -l)" -le 0 ]; then
    echo >&2 "ERROR: no files downloaded, or only old files exist"
    exit 1
  fi

  "$top/bin/backup-purge.sh" -k 14 "$local_dir"
}

################################################################################
function main() {
  local host
  host=$(hostname)

  backup_mount_dir -l "$locked_uuid" "$unlocked_uuid" "$mount_point"

  if [ "$host" = "medusa" ]; then
    do_sync ~/bin "$host/bin"
    do_sync ~/core "$host/core"
    do_sync ~/documents "$host/documents"
    do_sync ~/keys "$host/keys"
    do_sync ~/src/rc/cassini "$host/cassini"
    do_sync ~/texmf "$host/texmf"
    do_sync ~/training "$host/training"
  else
    do_backup ~/documents "$host/documents"
    do_backup ~/keys "$host/keys"
    do_backup ~/.password-store passwords
    do_backup ~/.var/app "$host/flatpack" --exclude='**/cache/'
    do_backup ~/.config/beets "$host/beets" --exclude='*.bak' --exclude='config.yaml'
  fi

  # All hosts:
  slugworth_fetch "/var/lib/gitea/dump" "gitea"
  slugworth_fetch "/var/lib/immich/backups" "immich/db"
  slugworth_fetch "/var/lib/immich/upload" "immich/images"
  slugworth_fetch "/var/lib/backup/kanidm" "kanidm"
  slugworth_fetch "/var/lib/backup/postgresql/miniflux" "miniflux"
  slugworth_fetch "/var/lib/backup/postgresql/vaultwarden" "vaultwarden"
}

################################################################################
main "$@"
