final: prev:
let
  maintainersOverlay = _final: prev: {
    lib = prev.lib.extend (
      _lfinal: lprev: {
        maintainers = lprev.maintainers // import ../maintainers/maintainer-list.nix;
      }
    );
  };

  byNameOverlay = import ../pkgs/top-level/by-name-overlay.nix ../pkgs/by-name;
  allPackagesOverlay = import ../pkgs/top-level/all-packages.nix;
in
(prev.lib.composeManyExtensions [
  maintainersOverlay
  byNameOverlay
  allPackagesOverlay
])
  final
  prev
