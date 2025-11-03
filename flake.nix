{
  description = "Peter's Backup Scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
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
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      nixosModules.backup-scripts = import ./nixos;

      packages = forAllSystems (system: {
        backup-scripts = import ./. { pkgs = nixpkgsFor.${system}; };
      });

      overlays.backup-scripts = final: prev: (prev.pjones or { }) // {
        backup-scripts = self.packages.${prev.system}.backup-scripts;
      };

      checks = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in
        lib.optionalAttrs pkgs.stdenv.isLinux {
          adhoc = import test/adhoc.nix { inherit pkgs; };
          postgresql = import test/postgresql.nix { inherit pkgs; };
          rsync = import test/rsync.nix { inherit pkgs; };
          snapshot = import test/snapshot.nix { inherit pkgs; };
        });

      devShells = forAllSystems (system: {
        default = nixpkgsFor.${system}.mkShell {
          inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
    };
}
