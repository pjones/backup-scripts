#!/usr/bin/env bash

################################################################################
# Backup some media files to my portable disk.
set -eu
set -o pipefail

################################################################################
server=10.0.1.8
mount_point=/run/media/pjones/Media

################################################################################
main() {
  if ! mountpoint --quiet "$mount_point"; then
    # force option is because the disk is formatted HFS:
    udisksctl mount \
      --block-device /dev/disk/by-uuid/bec6c3dd-7698-3e5b-9f80-038cf670cace \
      --options force,rw
  fi

  rsync \
    --verbose \
    --recursive \
    --links \
    --safe-links \
    --times \
    --delete-before \
    --delete-excluded \
    --prune-empty-dirs \
    --human-readable \
    --filter="+ movies" \
    --filter="+ music" \
    --filter="+ family" \
    --filter="+ tvshows/Anne of Green Gables (1985)" \
    --filter="+ tvshows/Anne of Green Gables: The Continuing Story (2000)" \
    --filter="+ tvshows/Anne of Green Gables: The Sequel (1987)" \
    --filter="+ tvshows/Antiques Roadshow (1997)" \
    --filter="+ tvshows/Catherine the Great (2019)" \
    --filter="+ tvshows/Charlie's Angels (1976)" \
    --filter="+ tvshows/Columbo (1971)" \
    --filter="+ tvshows/Episodes (2011)" \
    --filter="+ tvshows/Fantasy Island (1978)" \
    --filter="+ tvshows/Father Brown (2013)" \
    --filter="+ tvshows/Masters of Sex (2013)" \
    --filter="+ tvshows/Miss Fisher's Murder Mysteries (2012)" \
    --filter="+ tvshows/Orphan Black (2013)" \
    --filter="+ tvshows/Star Trek: Picard (2020)" \
    --filter="+ tvshows/Star Trek: The Next Generation (1987)" \
    --filter="+ tvshows/The Big Bang Theory (2007)" \
    --filter="+ tvshows/The Love Boat (1977)" \
    --filter="+ tvshows/The Munsters (1964)" \
    --filter="+ audiobooks" \
    --filter="- comedy" \
    --filter="- education" \
    --filter="- fitness" \
    --filter="- pictures" \
    --filter="- random" \
    --filter="- tvshows/*" \
    "$@" "$server:/var/media/" "$mount_point/"
}

################################################################################
main "$@"
