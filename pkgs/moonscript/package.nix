{
  nixpkgs,
  system,
  ...
}:
with nixpkgs;
with legacyPackages.${system};
with lua52Packages;
moonscript
