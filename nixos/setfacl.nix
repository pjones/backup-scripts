{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scripts.backup.setfacl;
  user = config.scripts.backup.user.name;
  name = "backup-setfacl";

  script = pkgs.writeShellScript "backup-setfacl" (
    lib.concatMapStringsSep "\n" (dir: ''
      ${pkgs.acl}/bin/setfacl --recursive --modify user:${user}:rX "${dir}"
    '') cfg.directories
  );
in
{
  options.scripts.backup.setfacl = {
    directories = lib.mkOption {
      type = with lib.types; listOf path;
      default = [ ];
      description = ''
        A list of directories that will have ACLs added to them so that the
        backup user can read files from them.
      '';
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 01:00:00";
      example = "*-*-* *:00/30:00";
      description = ''
        A systemd calendar specification to designate the frequency of the
        generated systemd unit.  You can use the "systemd-analyze calendar"
        command to validate your calendar specification.
      '';
    };
  };

  config = lib.mkIf (builtins.length cfg.directories > 0) {
    scripts.backup.adhoc.${name} = {
      script = toString script;
      schedule = cfg.schedule;
      user = "root";
      serviceName = name;
    };
  };
}
