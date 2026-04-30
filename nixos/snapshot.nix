{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scripts.backup.snapshot;

  snapshotType =
    { name, ... }:
    {
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
          default = config.scripts.backup.user.name;
          example = "root";
          description = "User to execute the script as.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = config.scripts.backup.user.group;
          description = "Group for the backup user.";
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
    inherit (snapshot)
      schedule
      user
      services
      serviceName
      ;

    path = [
      pkgs.bzip2
      pkgs.gnutar
      pkgs.util-linux
      config.scripts.backup.package
    ]
    ++ snapshot.path;

    script = ''
      set -eu
      set -o pipefail

      export BACKUP_TIMESTAMP="$(date +%Y-%m-%d.%s)"
      export BACKUP_LIB_DIR=${config.scripts.backup.package}/lib
      export BACKUP_LOG_DIR=stdout
      export BACKUP_DIR="${snapshot.destination}"
      export BACKUP_SRC="${snapshot.directory}"

      source "$BACKUP_LIB_DIR/backup.sh"

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

    serviceConfig =
      let
        needPerms = config.scripts.backup.user.enable && snapshot.user == config.scripts.backup.user.name;

        preStart = pkgs.writeShellScript "pre" ''
          cd "${snapshot.directory}"

          ${pkgs.findutils}/bin/find . \
            ${lib.concatMapStringsSep " " (n: "-name ${lib.escapeShellArg n}") snapshot.filePatterns} \
            -exec ${pkgs.acl}/bin/setfacl --recursive -m user:${snapshot.user}:rX '{}' ';'
        '';
      in
      lib.optionalAttrs needPerms {
        ExecStartPre = "+${preStart}";
      };
  };

  dirRule =
    snapshot:
    lib.concatStringsSep " " [
      "d"
      ''"${snapshot.directory}"''
      "0750"
      snapshot.user
      snapshot.group
      "-"
    ];
in
{
  options.scripts.backup.snapshot = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule snapshotType);
    default = { };
    description = "Attribute set of snapshot options.";
  };

  config = lib.mkIf (builtins.length (builtins.attrValues cfg) > 0) {
    scripts.backup.adhoc = lib.mapAttrs (_name: snapshotToScript) cfg;
    systemd.tmpfiles.rules = map dirRule (lib.attrValues cfg);
  };
}
