{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
let
  tests = pkgs.stdenvNoCC.mkDerivation {
    name = "postgresql-backup-test-scripts";
    src = ./.;
    phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

    installPhase = ''
      mkdir -p "$out/bin"
      install -m 0555 test.sh "$out/bin/postgresql-backup-test.sh"
    '';
  };

  database = "example";
in
pkgs.nixosTest {
  name = "backup-postgresql-test";

  nodes = {
    machine = { config, pkgs, ... }: {
      imports = [ ../../nixos ];
      environment.systemPackages = [ tests ];

      # Set up PostgreSQL:
      services.postgresql = {
        enable = true;
        ensureDatabases = [ database ];
      };

      # Configure backups:
      scripts.backup.postgresql = {
        enable = true;
        databases = [ database ];
      };
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("postgresql.service")
    machine.succeed("postgresql-backup-test.sh ${database}")
  '';
}
