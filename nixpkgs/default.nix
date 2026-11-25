{
  nixpkgs ? null,
  system ? builtins.currentSystem,
  config ? { },
  overlays ? [ ],
}:
let
  lockedNixpkgs =
    let
      lock = builtins.fromJSON (builtins.readFile ../flake.lock);
      inherit (lock.nodes.nixpkgs) locked;
    in
    fetchTarball {
      url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
      sha256 = locked.narHash;
    };

  nixpkgsSrc = if nixpkgs != null then nixpkgs else lockedNixpkgs;
  localOverlay = import ./lib/overlay.nix;
in
import nixpkgsSrc {
  inherit system config;
  overlays = [ localOverlay ] ++ overlays;
}
