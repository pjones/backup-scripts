{ pkgs ? import <nixpkgs> { }
}:
let
  unit = "backup-snapshot-test";

in
pkgs.nixosTest {
  name = unit;

  nodes = {
    machine = { config, pkgs, ... }: {
      imports = [ ../nixos ];

      scripts.backup.snapshot.test = {
        user = "root";
        directory = "/etc";
        destination = "/tmp/backup";
        filePatterns = [ "issue" ];
      };
    };
  };

  testScript = ''
    start_all()
    # Ensure the timer doesn't fire during tests:
    machine.systemctl("stop ${unit}.timer")
    machine.systemctl("start ${unit}.service")
    machine.wait_until_succeeds(
        "systemctl --no-pager show ${unit}.service | grep -E 'ActiveState=(inactive|failed)'"
    )
    file = machine.succeed("ls /tmp/backup | grep -F .tar.bz2")
    machine.succeed(f"tar tjf /tmp/backup/{file.rstrip()} | grep issue")
  '';
}
