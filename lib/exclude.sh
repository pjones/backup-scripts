################################################################################
# Functions to help build exclude files.
export BACKUP_EXCLUDE_DIR=${BACKUP_EXCLUDE_DIR:-$HOME/backup/exclude}
export BACKUP_EXCLUDE_FILE=${BACKUP_EXCLUDE_FILE:-$BACKUP_EXCLUDE_DIR/$BACKUP_NAME.exclude}

################################################################################
# Must be called before any exclude functions can be used.
function exclude_start () {
  log "preparing exclude file"
  local host_exclude_file=$BACKUP_ETC_DIR/$BACKUP_NAME.exclude

  mkdir -p $(dirname $BACKUP_EXCLUDE_FILE)
  rm -f $BACKUP_EXCLUDE_FILE

  if [ -r $host_exclude_file ]; then
    cp $host_exclude_file $BACKUP_EXCLUDE_FILE
  else
    touch $BACKUP_EXCLUDE_FILE
  fi

  # Some default exclude entries:
  exclude_dir $BACKUP_EXCLUDE_DIR
  exclude_dir $BACKUP_LOG_DIR
}

################################################################################
function exclude_dir () {
  for d in "$@"; do
    realpath --relative-base=$(pwd) $d >> $BACKUP_EXCLUDE_FILE
  done
}

################################################################################
# Exclude directories managed by a source code control system.
function exclude_sccs () {
  log "excluding all SCCS directories"

  find . -type d -name .git \
       -prune -printf '%h\n' \
       >> $BACKUP_EXCLUDE_FILE 2> /dev/null || :
}

################################################################################
function exclude_log_directories () {
  log "excluding all log directories"

  find . -type d -name log -prune -print \
       >> $BACKUP_EXCLUDE_FILE 2> /dev/null || :
}
