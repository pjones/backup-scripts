# Release History

## Version *UNRELEASED*

### New and Updated Features

  * Added NixOS module files and tests

### Breaking Changes

  * PostgreSQL database dumps now use the `--clean` option to drop the
    database before restoring, and OIDs are no longer included in the
    backup.

  * The `backup_via_rsync` function no longer passes the following
    flags to `rsync`.  If you need them you should give them to
    `backup_via_rsync` and it will forward them to `rsync`:

    - `--copy-dirlinks`
    - `--copy-links`

  * Automatic detection of host exclude files has been removed.
