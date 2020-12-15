#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
# Load all the lib files:
BACKUP_LIB_DIR=${BACKUP_LIB_DIR:-$(dirname "$0")}

# shellcheck source=common.sh
. "${BACKUP_LIB_DIR}/common.sh"

# shellcheck source=log.sh
. "${BACKUP_LIB_DIR}/log.sh"

# shellcheck source=exclude.sh
. "${BACKUP_LIB_DIR}/exclude.sh"

# shellcheck source=rdiff.sh
. "${BACKUP_LIB_DIR}/rdiff.sh"

# shellcheck source=rsync.sh
. "${BACKUP_LIB_DIR}/rsync.sh"
