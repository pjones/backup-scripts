#!/usr/bin/env bash

set -eu
set -o pipefail
set -x

if [ $# -ne 1 ]; then
  echo >&2 "ERROR: Please give the name of the database"
  exit 1
fi

# Vars:
database=$1
unit="backup-postgresql-$database"
service=$unit.service
timer=$unit.timer

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

# Ensure the backup doesn't run while we're testing:
systemctl stop "$timer"

# Create a table and some data to backup:
su - postgres -c "psql $database" <<EOF
CREATE TABLE widgets (
  id SERIAL,
  name TEXT
);

INSERT INTO widgets (name) VALUES ('keyboard'), ('monitor');
EOF

# Run the backup and verify it:
run_backup_service
file=$(find "/var/lib/backup/postgresql/$database" -type f -name '*.xz')

if [ -z "$file" ] || [ ! -e "$file" ]; then
  echo >&2 "ERROR: no backup file was created"
  exit 1
fi

# Simulate data loss:
rows=$(
  su - postgres -c "psql -qt $database" <<EOF
DELETE FROM widgets;
SELECT COUNT(*) FROM widgets;
EOF
)

if [ "$rows" -ne 0 ]; then
  echo >&2 "ERROR: should have deleted all widget rows!"
  exit 1
fi

# Restore the database from the backup:
xzcat "$file" | su - postgres -c psql

rows=$(
  su - postgres -c "psql -qt $database" <<EOF
SELECT COUNT(*) FROM widgets;
EOF
)

if [ "$rows" -ne 2 ]; then
  echo >&2 "ERROR: should have restored 2 rows!"
  exit 1
fi
