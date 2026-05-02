{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scripts.backup;
  user = "backup";

  # The scripts to use:
  package = pkgs.callPackage ../. { };
in
{
  imports = [
    ./adhoc.nix
    ./postgresql.nix
    ./rsync.nix
    ./snapshot.nix
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

      extraConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = "Extra attributes for the NixOS user account";
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
        createHome = true;
        description = "Backup user.";
        group = cfg.user.group;
        home = cfg.directory;
        isSystemUser = true;
        shell = pkgs.bash;
      }
      // cfg.user.extraConfig;

      users.groups."${cfg.user.group}" = { };
    })
  ];
}
