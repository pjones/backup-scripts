{
  description = "Peter's Backup Scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      # List of supported systems:
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "armv7l-linux"
        "i686-linux"
      ];

      # Function to generate a set based on supported systems:
      each =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          f pkgs system
        );
    in
    {
      nixosModules.backup-scripts = import ./nixos;

      packages = each (
        pkgs: system: {
          default = self.packages.${system}.backup-scripts;
          backup-scripts = pkgs.callPackage ./. { };
        }
      );

      overlays.default =
        final: prev:
        (prev.pjones or { })
        // {
          backup-scripts = self.packages.${prev.stdenv.hostPlatform.system}.backup-scripts;
        };

      checks = each (
        pkgs: system:
        lib.optionalAttrs pkgs.stdenv.isLinux {
          adhoc = import test/adhoc.nix { inherit pkgs; };
          postgresql = import test/postgresql.nix { inherit pkgs; };
          rsync = import test/rsync.nix { inherit pkgs; };
          snapshot = import test/snapshot.nix { inherit pkgs; };
        }
      );

      devShells = each (
        pkgs: system: {
          default = pkgs.mkShell {
            inputsFrom = builtins.attrValues self.packages.${system};
          };
        }
      );
    };
}
