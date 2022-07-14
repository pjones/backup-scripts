{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.scripts.backup.snapshot;

  snapshotType = { name, ... }: {
    options = {
      directory = lib.mkOption {
        type = lib.types.path;
        description = "The directory to take a snapshot of.";
      };

      destination = lib.mkOption {
        type = lib.types.path;
        description = "Directory where snapshots are stored.";
      };

      filePatterns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "." ];
        description = "List of shell globs to match files to capture.";
      };

      keep = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of old snapshots to keep.";
      };

      schedule = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 02:00:00";
        example = "*-*-* *:00/30:00";
        description = ''
          A systemd calendar specification to designate the frequency
          of the backup.  You can use the "systemd-analyze calendar"
          command to validate your calendar specification.
        '';
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "backup";
        example = "root";
        description = "User to execute the script as.";
      };

      path = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "List of packages to put in PATH.";
      };

      preScript = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Shell commands to run before the snapshot.";
      };

      postScript = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Shell commands to run after the snapshot.";
      };

      services = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "foo.service" ];
        description = ''
          Extra services to require and wait for.  Useful if you want
          to require certain systemd mounts to exist.
        '';
      };

      serviceName = lib.mkOption {
        type = lib.types.str;
        default = "backup-snapshot-${name}";
        description = "The name to use for the systemd units.";
      };
    };
  };

  snapshotToScript = snapshot: {
    inherit (snapshot) schedule user services serviceName;

    path = [
      pkgs.bzip2
      pkgs.gnutar
      pkgs.utillinux
      config.scripts.backup.package
    ] ++ snapshot.path;

    script = ''
      set -eu
      set -o pipefail
      umask 077

      export BACKUP_TIMESTAMP="$(date +%Y-%m-%d.%s)"
      export BACKUP_LIB_DIR=${config.scripts.backup.package}/lib
      export BACKUP_LOG_DIR=stdout
      export BACKUP_DIR="${snapshot.destination}"
      export BACKUP_SRC="${snapshot.directory}"

      mkdir -p "$BACKUP_DIR/$BACKUP_TIMESTAMP"
      cd "$BACKUP_SRC"

      ${snapshot.preScript}

      # Take a snapshot of the files:
      cp -a \
        ${lib.concatStringsSep " " snapshot.filePatterns} \
        "$BACKUP_DIR/$BACKUP_TIMESTAMP/"

      # Archive the snapshot:
      cd "$BACKUP_DIR"

      tar \
        --verbose \
        --create \
        --bzip2 \
        --file="$BACKUP_TIMESTAMP.tar.bz2" \
        "$BACKUP_TIMESTAMP"

      # Remove the snapshot directory:
      rm -r "$BACKUP_TIMESTAMP"

      ${snapshot.postScript}

      echo "purging old backups from $BACKUP_DIR"
      backup-purge.sh -k ${builtins.toString snapshot.keep} "$BACKUP_DIR"
    '';
  };
in
{
  options.scripts.backup.snapshot = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule snapshotType);
    default = { };
    description = "Attribute set of snapshot options.";
  };

  config = lib.mkIf (builtins.length (builtins.attrValues cfg) > 0) {
    scripts.backup.adhoc = lib.mapAttrs (_name: snapshotToScript) cfg;
  };
}

