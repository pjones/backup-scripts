#! @bash@/bin/bash

################################################################################
set -e
set -u

################################################################################
option_key_file=""

################################################################################
usage () {
cat <<EOF
Usage: $(basename "$0") [options]
Mount encrypted backup disks

Options:
  -h      This message
  -k FILE Read key from FILE
EOF
}

################################################################################
do_mount() {
  local disk=$1; shift
  local dir=$1; shift
  local mount_options=()

  if [ -n "$option_key_file" ] && [ -e "$option_key_file" ]; then
    mount_options+=("-k" "$option_key_file")
  fi

  mount-encrypted-dev "${mount_options[@]}" "$disk" "$dir"
}

################################################################################
while getopts "hk:" o; do
  case "${o}" in
    h) usage
       exit
       ;;

    k) option_key_file="$OPTARG"
       ;;

    *) exit 1
       ;;
  esac
done

shift $((OPTIND-1))

################################################################################
do_mount /dev/disk/by-uuid/a843062e-09e7-4096-9f38-4176002957cc /mnt/backup/home
do_mount /dev/disk/by-uuid/ffb3623a-c0f5-476f-9932-ad2f64b6a5b7 /mnt/backup/tm
do_mount /dev/disk/by-uuid/bd5fbda0-0376-49e3-ae88-7d4595fd0c4e /mnt/backup/misc
