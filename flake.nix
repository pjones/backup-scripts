{
  description = "Peter's Backup Scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
  };

  outputs = { self, nixpkgs }:
    let
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

      defaultPackage =
        forAllSystems (system: self.packages.${system}.backup-scripts);

      overlay = final: prev: {
        pjones = (prev.pjones or { }) //
          { backup-scripts = self.packages.${prev.system}.backup-scripts; };
      };

      checks = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          lib = pkgs.lib;
        in
        lib.optionalAttrs pkgs.stdenv.isLinux
          {
            adhoc = import test/adhoc { inherit pkgs; };
            rsync = import test/rsync { inherit pkgs; };
            postgresql = import test/postgresql { inherit pkgs; };
          });

      devShell = forAllSystems
        (system:
          nixpkgsFor.${system}.mkShell {
            inputsFrom = builtins.attrValues self.packages.${system};
          });
    };
}
