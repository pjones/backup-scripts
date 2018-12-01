#!/bin/bash

################################################################################
# Remove old backup files from a directory.
set -e
set -u

################################################################################
option_type="f"
option_keep=14

################################################################################
usage () {
cat <<EOF
Usage: purge-old-files.sh [options] directory

  -d      Purge directories instead of files
  -h      This message
  -k NUM  Keep NUM existing files
EOF
}

################################################################################
while getopts "hdk:" o; do
  case "${o}" in
    h) usage
       exit
       ;;

    d) option_type="d"
       ;;

    k) option_keep=$OPTARG
       ;;

    *) exit 1
       ;;
  esac
done

shift $((OPTIND-1))

################################################################################
if [ $# -ne 1 ] || [ ! -d "$1" ]; then
  >&2 echo "ERROR: provide exactly one directory name"
  exit 1
fi

################################################################################
_dir_entries() {
  local dir=$1; shift
  find "$dir" -mindepth 1 -maxdepth 1 -type "$option_type" "$@" | sort
}

################################################################################
count=$(_dir_entries "$1" | wc -l)
num_to_remove=0
to_remove=()

if [ "$count" -gt "$option_keep" ]; then
  num_to_remove=$((count - option_keep))
  mapfile -t to_remove < <(_dir_entries "$1" | head --lines="$num_to_remove")
  rm -r "${to_remove[@]}"
fi
