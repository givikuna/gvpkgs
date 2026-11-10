{
  nixpkgs,
  fenix,
  system,
}:

let
  inherit (nixpkgs) lib;

  entries = builtins.readDir ./.;

  packageDirs = lib.filterAttrs (name: type: type == "directory") entries;

in
lib.mapAttrs (
  name: _:
  nixpkgs.callPackage (./. + "/${name}/package.nix") {
    inherit fenix nixpkgs system;
  }
) packageDirs
