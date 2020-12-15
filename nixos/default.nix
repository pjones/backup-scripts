{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.scripts.backup;
  user = "backup";

  # The scripts to use:
  package = import ../. { inherit pkgs; };
in
{
  imports = [
    ./adhoc.nix
    ./postgresql.nix
    ./rsync.nix
  ];

  #### Interface
  options.scripts.backup = {
    user = {
      enable = lib.mkEnableOption ''
        Use a dedicated user and group for backups.
      '';

      name = lib.mkOption {
        type = lib.types.str;
        default = user;
        description = "User to perform backups as.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = user;
        description = "Group for the backup user.";
      };
    };

    directory = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/backup";
      description = ''
        Base directory where backups will be stored.  Each
        host/application to back up will get a directory under this
        base directory.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "The package providing the backup scripts.";
    };
  };

  #### Implementation
  config = lib.mkMerge [
    # Use a dedicated user/group:
    (lib.mkIf cfg.user.enable {
      users.users."${cfg.user.name}" = {
        description = "Backup user.";
        home = cfg.directory;
        createHome = true;
        group = cfg.user.group;
        isSystemUser = true;
      };

      users.groups."${cfg.user.group}" = { };
    })
  ];
}
