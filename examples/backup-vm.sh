#!/usr/bin/env bash

################################################################################
# Backup a libvirt Virtual Machine
set -eu
set -o pipefail

################################################################################
option_vm=win11

################################################################################
unlocked_uuid=b5d4ccdb-0a0e-493d-96c7-bd217145fecd
mount_point=/run/media/pjones/$unlocked_uuid

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message

EOF
}

################################################################################
function main() {
  while getopts "h" o; do
    case "${o}" in
    h)
      usage
      exit
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [ ! -d "$mount_point" ]; then
    echo >&2 "ERROR: please insert the backup drive"
    exit 1
  fi

  backup_dir="$mount_point/vm-$option_vm"
  mkdir -p "$backup_dir"

  # https://github.com/abbbi/virtnbdbackup
  sudo virtnbdbackup \
    --uri "${VIRSH_DEFAULT_CONNECT_URI:-qemu:///system}" \
    --level auto \
    --domain "$option_vm" \
    --output "$backup_dir"
}

################################################################################
main "$@"
