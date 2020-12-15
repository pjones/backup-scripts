# Release History

## Version *UNRELEASED*

### New and Updated Features

  * Added NixOS module files and tests

### Breaking Changes

  * PostgreSQL database dumps now use the `--clean` option to drop the
    database before restoring, and OIDs are no longer included in the
    backup.

  * Automatic detection of host exclude files has been removed.
