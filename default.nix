{ pkgs ? import <nixpkgs> { }
}:

with pkgs.lib;
let
  # Build a PATH list for each dependency:
  mkPkgPath = concatMapStringsSep ":" (pkg: "${pkg}/bin");

in
pkgs.stdenvNoCC.mkDerivation rec {
  name = "backup-scripts";
  meta.description = "Peter's backup scripts";
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
  src = ./.;

  buildInputs = with pkgs; [
    bash
    coreutils
    e2fsprogs
    eject
    findutils
    gnused
    openssh
    rdiff-backup
    rsync
    utillinux
    xz
  ];

  installPhase = ''
    # Variables to substitute into the scripts:
    export pathextras=${mkPkgPath buildInputs}
    export libdir=$out/lib

    for f in $(find bin lib examples scripts -type f); do
      mkdir -p $out/$(dirname $f)
      substituteAll $f $out/$f
    done

    find $out/bin $out/scripts $out/examples \
      -type f -exec chmod 0555 '{}' ';'
  '';
}
