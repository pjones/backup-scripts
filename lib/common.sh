################################################################################
set -e
set -u

################################################################################
export BACKUP_NAME=`basename $0 .sh|sed 's/^backup-//'`
export BACKUP_ETC_DIR=${BACKUP_ETC_DIR:-@etcdir@}

################################################################################
option_verbose=0

################################################################################
function usage() {
local name=`basename $0`
cat <<EOF
Usage: $name [options]

  -h      This message
  -v      Enable verbose logging
EOF
}

################################################################################
while getopts "hv" o; do
  case "${o}" in
    h) usage
       exit
       ;;

    v) option_verbose=1
       ;;

    *) exit 1
       ;;
  esac
done

shift $((OPTIND-1))
