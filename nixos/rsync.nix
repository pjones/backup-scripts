# Hard-linked backups via rsync.
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.scripts.backup;
  port = builtins.head config.services.openssh.ports;

  # Sanitize the name of a directory.
  cleanDir = path:
    lib.replaceStrings [ "/" ] [ "-" ]
      (lib.removePrefix "/" path);

  # Backup options.
  backupOpts = { config, ... }: {
    options = {
      remote = {
        host = lib.mkOption {
          type = lib.types.str;
          example = "example.com";
          description = "Host name for the machine to back up.";
        };

        port = lib.mkOption {
          type = lib.types.ints.positive;
          default = port;
          example = 22;
          description = "SSH port on the remote machine.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "backup";
          example = "root";
          description = "User name on the remote machine to use.";
        };

        directory = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/backup";
          example = "/var/backup";
          description = "Remote directory to sync to the local machine.";
        };


        key = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/home/backup/.ssh/id_ed25519";
          description = ''
            Optional SSH key to use when connecting to the remote
            machine.
          '';
        };
      };

      local = {
        user = lib.mkOption {
          type = lib.types.str;
          default = cfg.rsync.user;
          example = "root";
          description = "The local user running rsync.";
        };

        directory = lib.mkOption {
          type = lib.types.path;
          example = "/var/lib/backup/rsync/job";
          description = "Local directory where files are synced to.";
        };

        keep = lib.mkOption {
          type = lib.types.ints.positive;
          default = 7;
          example = 14;
          description = "Number of backups to keep when deleting older backups.";
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
      };

      schedule = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 02:00:00";
        example = "*-*-* *:00/30:00";
        description = ''
          A systemd calendar specification to designate the frequency
          of the backup.  You can use the "systemd-analyze calendar"
          command to validate your calendar specification.

          When increasing the frequency of the backups you should
          consider changing the number of backups that you keep.
        '';
      };
    };

    config = {
      local.directory =
        lib.mkDefault
          (lib.concatStringsSep "/" [
            cfg.rsync.directory
            config.remote.host
            (cleanDir config.remote.directory)
          ]);
    };
  };

  # systemd tmp file rules:
  tmpfiles = opts:
    "d '${opts.local.directory}' 0700 ${opts.local.user} ${cfg.rsync.group} -";

  # Generate a systemd service for a backup.
  service = _unit: opts:
    rec {
      description = "rsync backup for ${opts.remote.host}:${opts.remote.directory}";
      path = [ pkgs.coreutils cfg.package ];
      wants = opts.local.services;
      after = wants;

      serviceConfig = {
        Type = "simple";
        User = opts.local.user;
      };

      script = ''
        export BACKUP_LIB_DIR=${cfg.package}/lib
        export BACKUP_LOG_DIR=stdout
        export BACKUP_SSH_KEY=${toString opts.remote.key}
        export BACKUP_SSH_PORT=${toString opts.remote.port}
        . "${cfg.package}/lib/backup.sh"

        backup_via_rsync \
          "${opts.remote.user}@${opts.remote.host}:${opts.remote.directory}" \
          "${opts.local.directory}"

        backup-purge.sh \
          -k "${toString opts.local.keep}" \
          -d "${opts.local.directory}"
      '';
    };

  # Generate a systemd timer for a backup.
  timer = unit: opts: {
    description = "Scheduled Backup of ${opts.remote.host}:${opts.remote.directory}";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = opts.schedule;
    timerConfig.RandomizedDelaySec = "5m";
    timerConfig.Unit = "${unit}.service";
  };

  # Generate systemd services and timers.
  toSystemd = f:
    lib.foldr
      (a: b:
        let unit = "backup-rsync-${a.remote.host}-${cleanDir a.remote.directory}";
        in b // { "${unit}" = f unit a; })
      { }
      cfg.rsync.schedules;
in
{
  #### Interface
  options.scripts.backup.rsync = {
    enable = lib.mkEnableOption "rsync backups";

    directory = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.directory}/rsync";
      description = ''
        Base directory for rsync backups when local.directory is not set.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User to perform backups as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      description = "Group for the backup user.";
    };

    schedules = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule backupOpts);
      default = [ ];
      description = "List of backups to perform.";
    };
  };

  #### Implementation
  config = lib.mkIf cfg.rsync.enable {
    scripts.backup.rsync.user =
      lib.mkDefault
        (if cfg.user.enable
        then cfg.user.name
        else "root");

    scripts.backup.rsync.group =
      lib.mkDefault
        (if cfg.user.enable
        then cfg.user.group
        else "wheel");

    systemd = {
      services = toSystemd service;
      timers = toSystemd timer;
      tmpfiles.rules = map tmpfiles cfg.rsync.schedules;
    };
  };
}
