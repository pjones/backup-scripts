################################################################################
export BACKUP_RDIFF_DIR=${BACKUP_RDIFF_DIR:-$HOME/backup/${BACKUP_NAME:-$(hostname)}}

################################################################################
# Backup the current directory to `BACKUP_RDIFF_DIR'.
backup_via_rdiff() {
  log "backing up with rdiff-backup"

  force_flag=""

  if [ "${option_force:-0}" = 1 ]; then
    force_flag="--force"
  fi

  rdiff-backup \
    --exclude-filelist "${BACKUP_EXCLUDE_FILE:-/dev/null}" \
    --exclude-other-filesystems --exclude-sockets --print-statistics \
    "$force_flag" "$(pwd)" "$BACKUP_RDIFF_DIR"
}
