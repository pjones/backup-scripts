#!/usr/bin/env bash

################################################################################
# Backup a libvirt Virtual Machine
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

################################################################################
option_vm=win11

################################################################################
function main() {
  backup_mount_dir \
    -l "$locked_uuid" \
    "$unlocked_uuid" \
    "$mount_point"

  backup_dir="$mount_point/backup/vm-$option_vm"
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
