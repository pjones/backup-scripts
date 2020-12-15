#!/usr/bin/env bash

set -eu
set -o pipefail
set -x

unit="backup-rsync-localhost-tmp-backup"
service="$unit.service"
timer="$unit.timer"

dir=/var/lib/backup/rsync/localhost/tmp-backup

# Return the current state of the backup service:
get_service_state() {
  systemctl --no-pager show "$service" |
    grep '^ActiveState=' |
    sed -E 's/^[^=]+=//'
}

# Run the backup script:
run_backup_service() {
  systemctl start "$service"

  # Wait for it to start:
  while [ "$(get_service_state)" != "active" ] &&
    [ "$(get_service_state)" != "failed" ]; do
    :
  done

  # Wait for it to finish:
  while [ "$(get_service_state)" = "active" ]; do :; done
}

# Returns the most recent backup directory.
most_recent_backup() {
  find "$dir" -mindepth 1 -maxdepth 1 -type d | sort | tail -1
}

# Prepare a fake file for backing up:
mkdir /tmp/backup
echo OKAY >/tmp/backup/file

# Manually start the backup.
systemctl stop "$timer"
run_backup_service

# Verify that a file was backed up:
first_backup=$(most_recent_backup)

if [ "$(cat "$first_backup/file")" != OKAY ]; then
  echo >&2 "ERROR: backup file had wrong file contents"
  ls -Ral /var/lib/backup/rsync
  exit 1
fi

# Run another backup and verify the file was hard linked:
run_backup_service

last_backup=$(most_recent_backup)

if [ "$last_backup" = "$first_backup" ]; then
  echo >&2 "ERROR: second backup run didn't produce a new directory"
  exit 1
fi

file_a=$(stat --printf %i "$first_backup/file")
file_b=$(stat --printf %i "$last_backup/file")

if [ "$file_a" -ne "$file_b" ]; then
  echo >&2 "ERROR: backing up the same file twice used two inodes!"
  exit 1
fi
