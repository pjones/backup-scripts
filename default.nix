{ pkgs ? import <nixpkgs> { }
}:

with pkgs.lib;

let
  # Build a PATH list for each dependency:
  mkPkgPath = concatMapStringsSep ":" (pkg: "${pkg}/bin");

in pkgs.stdenvNoCC.mkDerivation rec {
  name = "backup-scripts";
  meta.description = "Peter's backup scripts";
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
  src = ./.;

  buildInputs = with pkgs; [
    bash
    coreutils
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
    export etcdir=$out/etc
    export libdir=$out/lib

    for f in $(find bin etc lib scripts -type f); do
      mkdir -p $out/$(dirname $f)
      substituteAll $f $out/$f
    done

    find $out/bin $out/scripts -type f -exec chmod 0555 '{}' ';'
  '';
}
