#!/usr/bin/env bash

################################################################################
backup_mounted_dirs=()
backup_mounted_unlocked_ids=()
backup_mounted_locked_ids=()

################################################################################
function backup_mount_dir() {
  local locked_uuid
  local unlocked_uuid
  local mount_point
  local pass_file="machines/hq.pmade.com/luks-boot"

  OPTIND=1
  while getopts "l:p:" o; do
    case "${o}" in
    l)
      locked_uuid=$OPTARG
      ;;

    p)
      pass_file=$OPTARG
      ;;

    *)
      echo >&2 "ERROR: invalid argument $o"
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [[ $# != 2 ]]; then
    echo >&2 "ERROR: backup_mount_dir needs two args"
    exit 1
  fi

  unlocked_uuid=$1
  mount_point=$2

  if [ ! -e "$mount_point" ] || ! mountpoint --quiet "$mount_point"; then
    echo "Unlocking and mounting backup disk..."

    if [[ -n $locked_uuid ]]; then
      udisksctl unlock \
        --block-device "/dev/disk/by-uuid/$locked_uuid" \
        --key-file <(pass "$pass_file" | head -1 | tr -d '\n')
    fi

    udisksctl mount --block-device "/dev/disk/by-uuid/$unlocked_uuid"

    backup_mounted_dirs+=("$mount_point")
    backup_mounted_unlocked_ids+=("$unlocked_uuid")
    backup_mounted_locked_ids+=("${locked_uuid:-}")
  fi
}

################################################################################
function backup_unmount_all() {
  local i=0

  if [[ ${option_keep_mounted:=0} == 0 ]]; then
    while [[ $i -lt ${#backup_mounted_dirs[@]} ]]; do
      log "backup_unmount_all[$i]"

      mount_point=${backup_mounted_dirs[$i]}
      unlocked_uuid=${backup_mounted_unlocked_ids[$i]}
      locked_uuid=${backup_mounted_locked_ids[$i]}

      if [ -e "$mount_point" ] && mountpoint --quiet "$mount_point"; then
        log "un-mounting $mount_point"
        udisksctl unmount --block-device "/dev/disk/by-uuid/$unlocked_uuid"
      fi

      if [ -e "/dev/disk/by-uuid/$unlocked_uuid" ]; then
        log "locking device /dev/disk/by-uuid/$unlocked_uuid"
        udisksctl lock --block-device "/dev/disk/by-uuid/$locked_uuid"
      fi

      i=$((i + 1))
    done

    backup_mounted_dirs=()
    backup_mounted_unlocked_ids=()
    backup_mounted_locked_ids=()
  fi
}

################################################################################
trap backup_unmount_all EXIT
