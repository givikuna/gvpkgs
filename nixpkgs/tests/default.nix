{
  nixpkgs,
  system,
}:
let
  pkgs = import ../default.nix {
    inherit nixpkgs system;
  };
  inherit (pkgs) lib;

  byNameDir = ../pkgs/by-name;
  discoverByName = import ../lib/discover-by-name.nix { inherit lib; };
  byNamePkgNames = builtins.attrNames (discoverByName byNameDir);

  allPackagesKeys = builtins.attrNames (import ../pkgs/top-level/all-packages.nix pkgs pkgs);
  localPkgNames = lib.unique (byNamePkgNames ++ allPackagesKeys);

  supportedPkgNames = builtins.filter (
    name:
    let
      val = pkgs.${name};
    in
    lib.isDerivation val && lib.meta.availableOn pkgs.stdenv.hostPlatform val
  ) localPkgNames;

  pkgChecks = lib.foldl' (
    acc: name:
    let
      pkg = pkgs.${name};
      rawTests = pkg.passthru.tests or { };
      validTests = lib.filterAttrs (_: lib.isDerivation) rawTests;
      testAttrs = lib.mapAttrs' (
        testName: testDrv: lib.nameValuePair "${name}-test-${testName}" testDrv
      ) validTests;
    in
    acc
    // {
      "${name}" = pkg;
    }
    // testAttrs
  ) { } supportedPkgNames;
in
{
  nixpkgs-by-name-check = import ./check-by-name.nix {
    inherit pkgs byNamePkgNames byNameDir;
  };
}
// pkgChecks
