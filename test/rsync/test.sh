#!/usr/bin/env bash

set -eu
set -o pipefail
set -x

unit="backup-rsync-localhost-tmp-backup"
service="$unit.service"
timer="$unit.timer"

dir=/var/lib/backup/rsync/localhost/tmp-backup
mkdir -p "$dir"
chown backup "$dir"

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

  if [ "$(get_service_state)" = "failed" ]; then
    echo >&2 "ERROR: backup service failed: "
    journalctl >&2 --no-pager --unit="$service"
    exit 1
  fi
}

# Returns the most recent backup directory.
most_recent_backup() {
  find "$dir" -mindepth 1 -maxdepth 1 -type d | sort | tail -1
}

# Prepare a fake file for backing up.  The directory structure is set
# up so that purging an older backup will run into permission issues
# unless the purging script is running as root or is run with the `-w`
# flag.
mkdir -p /tmp/backup/dir
echo OKAY >/tmp/backup/dir/file

chown -R backup /tmp/backup/dir
chmod -R u-w,go-rwx /tmp/backup/dir
chattr +i /tmp/backup/dir/file

# Put a symbolic link in the backup directory to make sure we handle
# it correctly:
(cd /tmp/backup &&
  ln -s "$(realpath "$(type -P sort)")" sort)

# Manually start the backup.
systemctl stop "$timer"
run_backup_service

# Verify that a file was backed up:
first_backup=$(most_recent_backup)

if [ "$(cat "$first_backup/dir/file")" != OKAY ]; then
  echo >&2 "ERROR: backup file had wrong file contents"
  ls -Ral /var/lib/backup/rsync
  exit 1
fi

if [ "$(stat -c %U "$first_backup/dir/file")" != backup ]; then
  echo >&2 "ERROR: backed up file has the wrong owner"
  exit 1
fi

if [ "$(stat -c %a "$first_backup/dir/file")" != 400 ]; then
  echo >&2 "ERROR: backed up file has the wrong mode"
  exit 1
fi

# Run another backup and verify the file was hard linked:
sleep 1 # Ensure we wait long enough to get a new file name
run_backup_service

second_backup=$(most_recent_backup)

if [ "$second_backup" = "$first_backup" ]; then
  echo >&2 "ERROR: second backup run didn't produce a new directory"
  exit 1
fi

file_a=$(stat --printf %i "$first_backup/dir/file")
file_b=$(stat --printf %i "$second_backup/dir/file")

if [ "$file_a" -ne "$file_b" ]; then
  echo >&2 "ERROR: backing up the same file twice used two inodes!"
  exit 1
fi

if [ ! -L "$second_backup/sort" ]; then
  echo >&2 "ERROR: symbolic link wasn't backup up properly"
  ls -l "$second_backup" >&2
  stat >&2 "$second_backup/sort"
  exit 1
fi

# Run the backup a third time.  This will cause a purge of the first
# backup which has an immutable file to test the `-w` flag to the
# backup purging script.
sleep 1 # Ensure we wait long enough to get a new file name
run_backup_service
final_backup=$(most_recent_backup)

if [ "$final_backup" = "$second_backup" ]; then
  echo >&2 "ERROR: final backup didn't produce a new backup directory"
  exit 1
fi

if [ -e "$first_backup" ]; then
  echo >&2 "ERROR: first backup was not purged"
  exit 1
fi

if [ "$(find "$dir" -mindepth 1 -maxdepth 1 | wc -l)" -ne 2 ]; then
  echo >&2 "ERROR: backup directory should have been purged"
  exit 1
fi
