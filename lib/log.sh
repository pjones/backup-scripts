#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
export BACKUP_LOG_DIR=${BACKUP_LOG_DIR:-/var/lib/backup/log}

################################################################################
# Where we're going to keep logs and signature files.
if [ "$BACKUP_LOG_DIR" != "stdout" ] && [ ! -t 1 ]; then
  log_file=$BACKUP_LOG_DIR/$BACKUP_NAME.log
  log_dir=$(dirname "$log_file")
  mkdir -p "$log_dir"
  exec >"$log_file" 2>&1
fi

################################################################################
echo "Starting backup"

################################################################################
die() {
  echo "ERROR:" "$@"
  echo
  [ -n "$log_file" ] && [ -e "$log_file" ] && cat "$log_file"
  exit 1
}

################################################################################
log() {
  now=$(date +'%Y-%m-%d %H:%M:%S')
  echo "[$now]:" "$@"
}

################################################################################
verbose() {
  if [ "${option_verbose:-0}" -eq 1 ]; then
    log "$@"
  fi
}
