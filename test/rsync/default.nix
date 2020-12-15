{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
let
  tests = pkgs.stdenvNoCC.mkDerivation {
    name = "rsync-backup-test-scripts";
    src = ./.;
    phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

    installPhase = ''
      mkdir -p "$out/bin"
      install -m 0555 test.sh "$out/bin/rsync-backup-test.sh"
    '';
  };

in
pkgs.nixosTest {
  name = "rsync-backup-test";

  nodes = {
    machine = { config, pkgs, ... }: {
      imports = [ ../../nixos ];
      services.openssh.enable = true;
      environment.systemPackages = [ tests ];

      users.users.root.openssh.authorizedKeys.keys = [
        (builtins.readFile ../data/ssh.id_ed25519.pub)
      ];

      scripts.backup.rsync = {
        enable = true;
        schedules = [
          {
            host = "localhost";
            directory = "/tmp/backup";
            user = "root";
            key = "/tmp/key";
            services = [ "sshd.service" ];
          }
        ];
      };
    };
  };

  testScript = ''
    start_all()
    machine.copy_from_host(
        "${../data/ssh.id_ed25519}", "/tmp/key"
    )
    machine.succeed("chmod 0600 /tmp/key")
    machine.wait_for_unit("sshd.service")
    machine.succeed("rsync-backup-test.sh")
  '';
}
