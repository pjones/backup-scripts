################################################################################
# Sync a directory using rsync.
#
#   $1: Origin directory (include trailing slash).
#   $2: Destination directory (include trailing slash).
sync_via_rsync() {
  if [ $# -ne 2 ]; then
    die "Usage: sync_via_rsync origin destination"
  fi

  origin="$1";      shift
  destination="$1"; shift

  log "syncing $origin -> $destination"
  rsync -au "$origin" "$destination"
}
