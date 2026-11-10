{
  pkgs,
  fenix,
  system,
}:

let
  inherit (pkgs) lib;

  entries = builtins.readDir ./.;

  packageDirs = lib.filterAttrs (name: type: type == "directory") entries;

in
lib.mapAttrs (
  name: _:
  pkgs.callPackage (./. + "/${name}/package.nix") {
    inherit fenix system;
  }
) packageDirs
