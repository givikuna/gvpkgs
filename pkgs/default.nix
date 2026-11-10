{
  nixpkgs,
  fenix,
  system,
}:

let
  pkgs = nixpkgs.legacyPackages.${system};
  gvlib = import ../lib {
    # pass lib
  };

  customLib = pkgs.lib.extend (
    final: prev: {
      maintainers = prev.maintainers // gvlib.maintainers;
    }
  );

  callPackage = customLib.callPackageWith (
    pkgs
    // {
      inherit fenix nixpkgs system;
      lib = customLib;
    }
  );

  entries = builtins.readDir ./.;
  packageDirs = customLib.filterAttrs (name: type: type == "directory") entries;
in
customLib.mapAttrs (name: _: callPackage (./. + "/${name}/package.nix") { }) packageDirs
