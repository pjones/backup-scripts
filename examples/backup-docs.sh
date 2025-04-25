#!/usr/bin/env bash

################################################################################
# Backup documents that are not synced with Git.
set -eu
set -o pipefail

################################################################################
top="$(realpath "$(dirname "$0")/..")"
export BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-$top/lib}

################################################################################
option_keep_mounted=0 # Changed by ../lib/backup.sh

################################################################################
# shellcheck source=../lib/backup.sh
. "$BACKUP_LIB_DIR/backup.sh"

################################################################################
locked_uuid=4da1879b-efd6-45fc-bd76-b2170008f839
unlocked_uuid=e549177c-0e84-4e12-be3f-a28b1476fc47
mount_point=/run/media/pjones/$unlocked_uuid
remote_vps_name=slugworth
remote_vps_host="${remote_vps_name}.private.pmade.com"

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -k      Keep the disk mounted after the backup
  -h      This message

EOF
}

################################################################################
cleanup() {
  if [ "$option_keep_mounted" -eq 0 ]; then
    if [ -e "$mount_point" ] && mountpoint --quiet "$mount_point"; then
      udisksctl unmount --block-device "/dev/disk/by-uuid/$unlocked_uuid"
    fi

    if [ -e "/dev/disk/by-uuid/$unlocked_uuid" ]; then
      udisksctl lock --block-device "/dev/disk/by-uuid/$locked_uuid"
    fi
  fi
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
sync_latest_archive_from_vps() {
  local src_dir=$1
  local dst_dir=$2
  local latest

  # shellcheck disable=SC2029
  latest=$(ssh root@${remote_vps_host} "ls -t $src_dir | head -1")
  mkdir --parents "$dst_dir"

  log "$latest -> $dst_dir/"
  rsync \
    --checksum \
    "root@${remote_vps_host}:$src_dir/$latest" \
    "$dst_dir/latest.${latest##*.}"
}

################################################################################
gitea_latest() {
  sync_latest_archive_from_vps \
    "/var/lib/backup/gitea" \
    "$mount_point/$remote_vps_name/gitea"
}

################################################################################
miniflux_latest() {
  sync_latest_archive_from_vps \
    "/var/lib/pgbackup/miniflux" \
    "$mount_point/$remote_vps_name/miniflux"
}

################################################################################
backup_immich() {
  do_backup \
    "root@$remote_vps_host:/var/lib/immich" \
    "$remote_vps_name/immich"
}

################################################################################
main() {
  local host
  host=$(hostname)

  if [ ! -e "$mount_point" ] || ! mountpoint --quiet "$mount_point"; then
    echo "Unlocking and mounting backup disk..."
    udisksctl unlock \
      --block-device "/dev/disk/by-uuid/$locked_uuid" \
      --key-file <(pass machines/hq.pmade.com/luks-boot | head -1 | tr -d '\n')

    udisksctl mount --block-device "/dev/disk/by-uuid/$unlocked_uuid"
  fi

  trap cleanup EXIT

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
  fi

  # All hosts:
  gitea_latest
  miniflux_latest
  backup_immich
}

################################################################################
main "$@"
