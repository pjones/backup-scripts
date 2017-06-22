################################################################################
# Functions to help build exclude files.
export BACKUP_EXCLUDE_DIR=${BACKUP_EXCLUDE_DIR:-$HOME/backup/exclude}
export BACKUP_EXCLUDE_FILE=${BACKUP_EXCLUDE_FILE:-$BACKUP_EXCLUDE_DIR/$BACKUP_NAME.exclude}

################################################################################
# Must be called before any exclude functions can be used.
exclude_start () {
  log "preparing exclude file"
  host_exclude_file=$BACKUP_ETC_DIR/$BACKUP_NAME.exclude
  exclude_dir=$(dirname "$BACKUP_EXCLUDE_FILE")

  mkdir -p "$exclude_dir"
  rm -f "$BACKUP_EXCLUDE_FILE"

  if [ -r "$host_exclude_file" ]; then
    log "using host exclude file: $host_exclude_file"
    cp "$host_exclude_file" "$BACKUP_EXCLUDE_FILE"
  else
    log "WARNING: no host exclude file found!"
    touch "$BACKUP_EXCLUDE_FILE"
  fi

  # Some default exclude entries:
  exclude_dir "$BACKUP_EXCLUDE_DIR"
  exclude_dir "$BACKUP_LOG_DIR"
}

################################################################################
exclude_dir () {
  for d in "$@"; do
    realpath "$d" >> "$BACKUP_EXCLUDE_FILE"
  done
}

################################################################################
# Exclude directories managed by a source code control system.
exclude_sccs () {
  log "excluding all SCCS directories"

  find "$(pwd)" -type d -name .git \
       -prune -printf '%h\n' \
       >> "$BACKUP_EXCLUDE_FILE" 2> /dev/null || :
}

################################################################################
exclude_log_directories () {
  log "excluding all log directories"

  find "$(pwd)" -type d -name log -prune -print \
       >> "$BACKUP_EXCLUDE_FILE" 2> /dev/null || :
}
