{ pkgs ? import <nixpkgs> { }
}:
let
  tests = pkgs.stdenvNoCC.mkDerivation {
    name = "rsync-backup-test-scripts";
    src = ./.;
    phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

    installPhase = ''
      mkdir -p "$out/bin"
      install -m 0555 rsync.sh "$out/bin/rsync-backup-test.sh"
    '';
  };

in
pkgs.nixosTest {
  name = "rsync-backup-test";

  nodes = {
    machine = { config, pkgs, ... }: {
      imports = [ ../nixos ];
      services.openssh.enable = true;
      environment.systemPackages = [ tests ];

      scripts.backup.user.enable = true;

      users.users.backup = {
        # Let the backup user accept SSH connections:
        shell = pkgs.bashInteractive;
        openssh.authorizedKeys.keys = [
          (builtins.readFile data/ssh.id_ed25519.pub)
        ];
      };

      scripts.backup.rsync = {
        enable = true;
        schedules = [
          {
            extraRsyncOptions = [ "--progress" "--stats" ];
            local.keep = 2;
            local.key = "/tmp/key";
            local.services = [ "sshd.service" ];
            local.user = "backup";
            remote.directory = "/tmp/backup";
            remote.host = "localhost";
            remote.user = "backup";
          }
        ];
      };
    };
  };

  testScript = ''
    start_all()
    machine.copy_from_host(
        "${data/ssh.id_ed25519}", "/tmp/key"
    )
    machine.succeed("chmod 0600 /tmp/key")
    machine.succeed("chown backup /tmp/key")
    machine.wait_for_unit("sshd.service")
    machine.succeed("rsync-backup-test.sh")
  '';
}
