#!/usr/bin/env bash

set -eu
set -o pipefail

################################################################################
export PATH=@pathextras@:/run/wrappers/bin:$PATH

################################################################################
HOME=${HOME:-/tmp} # Just in case.
BACKUP_NAME=$(basename "$0" .sh | sed 's/^backup-//')
export BACKUP_NAME

################################################################################
export option_verbose=0
export option_force=0
export option_keep_mounted=0

################################################################################
usage() {
  name=$(basename "$0")
  cat <<EOF
Usage: $name [options]

  -h      This message
  -f      Preform dangerous things (force)
  -k      Don't unmount any disks mounted during the backup
  -v      Enable verbose logging
EOF
}

################################################################################
while getopts "hfkv" o; do
  case "${o}" in
  h)
    usage
    exit
    ;;

  f)
    option_force=1
    ;;

  k)
    option_keep_mounted=1
    ;;

  v)
    option_verbose=1
    ;;

  *)
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

################################################################################
# Safer version of `cd'.
change_directory() {
  directory=${1:-$HOME}
  cd "$directory" || die "$directory doesn't exist!"
}
