################################################################################
BACKUP_RDIFF_DEFAULT_DIR=$HOME/backup/${BACKUP_NAME:-$(hostname)}
export BACKUP_RDIFF_DIR=${BACKUP_RDIFF_DIR:-$BACKUP_RDIFF_DEFAULT_DIR}

################################################################################
# Set the directory to back up to.  The given directory must be a
# mount point or this will fail.  This ensures the backup drive is
# mounted correctly.
backup_to_mount_point() {
  directory=${1:-$BACKUP_RDIFF_DEFAULT_DIR}

  if ! mountpoint -q "$directory"; then
    die "can't use $directory, it's not a mount point!"
  fi

  backup_to_directory "$directory"
}

################################################################################
# Set the directory to back up to.  The directory is created if it
# doesn't exist.  But its parent must exist or this will fail.
backup_to_directory() {
  directory=${1:-$BACKUP_RDIFF_DEFAULT_DIR}

  if [ ! -d "$(dirname "$directory")" ]; then
    die "can't use $directory, its parent doesn't exist!"
  fi

  mkdir -p "$directory"
  log "backup will go into $directory"
  BACKUP_RDIFF_DIR="$directory"
}

################################################################################
# Backup the current directory to `BACKUP_RDIFF_DIR'.
backup_via_rdiff() {
  log "backing up $(pwd) with rdiff-backup"

  force_flag=""

  if [ "${option_force:-0}" = 1 ]; then
    log "calling rdiff-backup with '--force' flag"
    force_flag="--force"
  elif [ ! -d "$BACKUP_RDIFF_DIR/rdiff-backup-data" ]; then
    log "first run, using '--force'"
    force_flag="--force"
  fi

  rdiff-backup \
    --exclude-filelist "${BACKUP_EXCLUDE_FILE:-/dev/null}" \
    --exclude-other-filesystems --exclude-sockets --print-statistics \
    $force_flag "$(pwd)" "$BACKUP_RDIFF_DIR"
}
