baseDirectory:

final: prev:
let
  discoverByName = import ../../lib/discover-by-name.nix { inherit (prev) lib; };
  packages = discoverByName baseDirectory;
in
prev.lib.mapAttrs (_: entry: final.callPackage entry.file { }) packages
