################################################################################
set -e
set -u

################################################################################
export PATH=@pathextras@:$PATH

################################################################################
BACKUP_NAME=$(basename "$0" .sh|sed 's/^backup-//')
BACKUP_ETC_DIR=${BACKUP_ETC_DIR:-@etcdir@}
export BACKUP_NAME BACKUP_ETC_DIR

################################################################################
export option_verbose=0
export option_force=0

################################################################################
usage() {
name=$(basename "$0")
cat <<EOF
Usage: $name [options]

  -h      This message
  -f      Preform dangerous things (force)
  -v      Enable verbose logging
EOF
}

################################################################################
while getopts "hfv" o; do
  case "${o}" in
    h) usage
       exit
       ;;

    f) option_force=1
       ;;

    v) option_verbose=1
       ;;

    *) exit 1
       ;;
  esac
done

shift $((OPTIND-1))

################################################################################
# Safer version of `cd'.
change_directory() {
  directory=${1:-$HOME}
  cd "$directory" || die "$directory doesn't exist!"
}
