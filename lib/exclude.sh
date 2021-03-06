#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
# Functions to help build exclude files.
export BACKUP_EXCLUDE_DIR=${BACKUP_EXCLUDE_DIR:-/var/lib/backup/exclude}
export BACKUP_EXCLUDE_FILE=${BACKUP_EXCLUDE_FILE:-$BACKUP_EXCLUDE_DIR/$BACKUP_NAME.exclude}

################################################################################
# Must be called before any exclude functions can be used.
exclude_start() {
  log "preparing exclude file"
  exclude_dir=$(dirname "$BACKUP_EXCLUDE_FILE")

  mkdir -p "$exclude_dir"
  rm -f "$BACKUP_EXCLUDE_FILE"

  # Some default exclude entries:
  exclude_dir "$BACKUP_EXCLUDE_DIR"
  exclude_dir "$BACKUP_LOG_DIR"
}

################################################################################
# An alternative to `exclude_start', creates a dummy exclude file that
# doesn't exclude anything.
exclude_nothing() {
  log "creating dummy exclude file (exclude_nothing)"
  cat /dev/null >"$BACKUP_EXCLUDE_FILE"
}

################################################################################
exclude_dir() {
  for d in "$@"; do
    realpath "$d" >>"$BACKUP_EXCLUDE_FILE"
  done
}

################################################################################
# Exclude directories managed by a source code control system.
exclude_sccs() {
  log "excluding all SCCS directories"

  find "$(pwd)" -type d -name .git \
    -prune -printf '%h\n' \
    >>"$BACKUP_EXCLUDE_FILE" 2>/dev/null || :
}

################################################################################
exclude_log_directories() {
  log "excluding all log directories"

  find "$(pwd)" -type d -name log -prune -print \
    >>"$BACKUP_EXCLUDE_FILE" 2>/dev/null || :
}
