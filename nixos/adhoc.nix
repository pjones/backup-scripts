# Run any script to perform a backup.
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.scripts.backup;

  scriptOpts = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Unique name for this backup script.";
      };

      path = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "List of packages to put in PATH.";
      };

      script = lib.mkOption {
        type = lib.types.lines;
        description = "Script to run.";
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

    config = {
      name = lib.mkDefault name;
    };
  };

  # Generate a systemd service for a backup.
  service = _unit: opts: rec {
    description = "${opts.name} backup";
    path = [ pkgs.coreutils cfg.package ] ++ opts.path;
    wants = opts.services;
    after = wants;
    script = opts.script;
    serviceConfig.Type = "simple";
    serviceConfig.User = opts.user;
  };

  # Generate a systemd timer for a backup.
  timer = unit: opts: {
    description = "Scheduled ${opts.name} backup";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = opts.schedule;
    timerConfig.RandomizedDelaySec = "5m";
    timerConfig.Unit = "${unit}.service";
  };

  # Generate systemd services and timers.
  toSystemd = f:
    lib.foldr
      (a: b:
        let unit = "backup-adhoc-${a.name}";
        in b // { ${unit} = f unit a; })
      { }
      (lib.attrValues cfg.adhoc);

in
{
  #### Interface
  options.scripts.backup.adhoc = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule scriptOpts);
    default = { };

    example = {
      copy-files = {
        script = "cp ~/.config ~/.config.bk";
      };
    };

    description = "Set of ad hoc backup scripts to run.";
  };

  #### Implementation
  config = {
    systemd.services = toSystemd service;
    systemd.timers = toSystemd timer;
  };
}
