{
  pkgs ? import <nixpkgs> { },
}:
let
  unit = "backup-setfacl";

in
pkgs.testers.nixosTest {
  name = unit;

  nodes = {
    machine =
      { ... }:
      {
        imports = [ ../nixos ];

        scripts.backup = {
          user.enable = true;
          setfacl.directories = [ "/root" ];
        };
      };
  };

  testScript = ''
    # Ensure the timer doesn't fire during tests:
    machine.systemctl("stop ${unit}.timer")

    # Create a file for testing:
    machine.succeed("touch /root/test-file")
    machine.succeed("chmod 0400 /root/test-file")

    # Run the "backup" job:
    machine.systemctl("start ${unit}.service")
    machine.wait_until_succeeds(
        "systemctl --no-pager show ${unit}.service | grep -E 'ActiveState=(inactive|failed)'"
    )

    # Ensure the backup user can read the test file:
    machine.succeed("su - backup -c 'test -r /root/test-file'")
  '';
}
