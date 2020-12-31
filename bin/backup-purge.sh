#!/usr/bin/env bash

################################################################################
# Remove old backup files from a directory.
set -eu
set -o pipefail

################################################################################
option_type="f"
option_keep=14
option_chmod=0

################################################################################
usage() {
  cat <<EOF
Usage: purge-old-files.sh [options] directory

  -d      Purge directories instead of files
  -h      This message
  -k NUM  Keep NUM existing files
  -w      Make files writable so they can be removed
EOF
}

################################################################################
while getopts "hdk:w" o; do
  case "${o}" in
  h)
    usage
    exit
    ;;

  d)
    option_type="d"
    ;;

  k)
    option_keep=$OPTARG
    ;;

  w)
    option_chmod=1
    ;;

  *)
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

################################################################################
if [ $# -ne 1 ] || [ ! -d "$1" ]; then
  echo >&2 "ERROR: provide exactly one directory name"
  exit 1
fi

################################################################################
_dir_entries() {
  local dir=$1
  shift
  find "$dir" -mindepth 1 -maxdepth 1 -type "$option_type" "$@" | sort
}

################################################################################
count=$(_dir_entries "$1" | wc -l)
num_to_remove=0
to_remove=()

if [ "$count" -gt "$option_keep" ]; then
  num_to_remove=$((count - option_keep))
  echo "number of old backups to purge: $num_to_remove"

  mapfile -t to_remove < <(_dir_entries "$1" | head --lines="$num_to_remove")

  for entry in "${to_remove[@]}"; do
    echo "purging old backup: $entry"

    if [ "$option_chmod" -eq 1 ]; then
      chmod -R u+w "$entry" || :
      chattr -R -i "$entry" || :
    fi

    rm \
      --force \
      --one-file-system \
      --preserve-root \
      --recursive \
      --verbose \
      "$entry"
  done
else
  echo "no backups need to be purged yet"
fi
