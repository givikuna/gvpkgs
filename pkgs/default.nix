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
  let
    pkgs = nixpkgs.legacyPackages.${system};
  in
  (with pkgs; callPackage) (./. + "/${name}/package.nix") {
    inherit fenix nixpkgs system;
  }
) packageDirs
