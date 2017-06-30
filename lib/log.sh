################################################################################
export BACKUP_LOG_DIR=${BACKUP_LOG_DIR:-/var/lib/backup/log}

################################################################################
# Where we're going to keep logs and signature files.
log_file=$BACKUP_LOG_DIR/$BACKUP_NAME.log
log_dir=$(dirname "$log_file")

################################################################################
mkdir -p "$log_dir"
echo "Starting backup" > "$log_file"
exec 4>&1 # save STDOUT to FD 4 so we can restore in die()
[ -t 1 ] || exec > "$log_file" 2>&1

################################################################################
die () {
  exec 1>&4 # Redirect STDOUT back to the original STDOUT.
  echo "ERROR:" "$@"
  echo
  cat "$log_file"
  exit 1
}

################################################################################
log () {
  now=$(date +'%Y-%m-%d %H:%M:%S')
  echo "[$now]:" "$@"
}

################################################################################
verbose () {
  if [ "${option_verbose:-0}" -eq 1 ]; then
    log "$@"
  fi
}
