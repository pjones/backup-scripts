{ stdenvNoCC
, lib
, bash
, coreutils
, e2fsprogs
, eject
, findutils
, gnused
, openssh
, rdiff-backup
, rsync
, util-linux
, virtnbdbackup
, xz
}:

stdenvNoCC.mkDerivation rec {
  name = "backup-scripts";
  meta.description = "Peter's backup scripts";
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
  src = ./.;

  buildInputs = [
    bash
    coreutils
    e2fsprogs
    eject
    findutils
    gnused
    openssh
    rdiff-backup
    rsync
    util-linux
    virtnbdbackup
    xz
  ];

  installPhase = ''
    # Variables to substitute into the scripts:
    export pathextras=${lib.makeBinPath buildInputs}
    export libdir=$out/lib

    for f in $(find bin lib examples scripts -type f); do
      mkdir -p $out/$(dirname $f)
      substituteAll $f $out/$f
    done

    find $out/bin $out/scripts $out/examples \
      -type f -exec chmod 0555 '{}' ';'
  '';
}
