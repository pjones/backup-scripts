#!/bin/sh

################################################################################
TOP=$(realpath "$(dirname "$0")/..")

################################################################################
export BACKUP_LIB_DIR=$TOP/lib
export BACKUP_ETC_DIR=$TOP/etc

################################################################################
bash "$TOP"/bin/backup-medusa.sh