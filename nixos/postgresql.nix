# Simple backups for PostgreSQL.
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.scripts.backup;
  pguser = "postgres";

  # systemd tmp file rules:
  tmpfiles = database:
    lib.concatStringsSep " " [
      "d"
      ''"${cfg.postgresql.directory}/${database}"''
      "0750"
      pguser
      pguser
      "-"
    ];

  # systemd service:
  service = _unit: database: {
    description = "Backup PostgreSQL Database ${database}";
    after = [ "postgresql.service" ];

    path = [
      pkgs.coreutils
      config.services.postgresql.package
      cfg.package
    ];

    serviceConfig = {
      Type = "simple";
      User = pguser;
    };

    script = ''
      export BACKUP_DIRECTORY="${cfg.postgresql.directory}"
      export BACKUP_LOG_DIR=stdout
      backup-postgresql-dump.sh "${database}"
      backup-purge.sh -k ${toString cfg.postgresql.keep} \
        "${cfg.postgresql.directory}/${database}"
    '';
  };

  # systemd timer:
  timer = unit: database: {
    description = "Scheduled Backup of PostgreSQL ${database}";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = cfg.postgresql.schedule;
    timerConfig.RandomizedDelaySec = "5m";
    timerConfig.Unit = "${unit}.service";
  };

  # Generate systemd services and timers.
  toSystemd = f:
    lib.foldr
      (a: b:
        let unit = "backup-postgresql-${a}";
        in b // { "${unit}" = f unit a; })
      { }
      cfg.postgresql.databases;
in
{
  #### Interface
  options.scripts.backup.postgresql = {
    enable = lib.mkEnableOption "Backup PostgreSQL Databases.";

    databases = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.str;
      example = [ "store" ];
      description = "Database names to backup.";
    };

    directory = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/backup/postgresql";
      description = "Base directory where dumps are stored.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 00/2:00:00";
      description = "A systemd OnCalendar formatted frequency specification.";
    };

    keep = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12;
      description = "Number of backups to keep when deleting older backups.";
    };
  };

  #### Implementation
  config = lib.mkIf cfg.postgresql.enable (
    let
      user = if cfg.user.enable then cfg.user.name else "root";
    in
    {
      systemd = {
        services = toSystemd service;
        timers = toSystemd timer;

        tmpfiles.rules =
          [ "d ${cfg.postgresql.directory} 0750 ${user} ${pguser} -" ]
          ++ map tmpfiles cfg.postgresql.databases;
      };
    }
  );
}
