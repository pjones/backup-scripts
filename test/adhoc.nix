{
  pkgs ? import <nixpkgs> { },
}:
let
  unit = "backup-adhoc-test";

in
pkgs.testers.nixosTest {
  name = "backup-script-test";

  nodes = {
    machine =
      { ... }:
      {
        imports = [ ../nixos ];

        scripts.backup.adhoc.test = {
          user = "root";
          script = ''
            cp "$(realpath /etc/issue)" /tmp/issue
          '';
        };
      };
  };

  testScript = ''
    start_all()
    # Ensure the timer doesn't fire during tests:
    machine.systemctl("stop ${unit}.timer")
    machine.systemctl("start ${unit}.service")
    machine.wait_until_succeeds(
        "systemctl --no-pager show ${unit}.service | grep 'ActiveState=inactive'"
    )
    machine.succeed("grep NixOS /tmp/issue")
  '';
}
