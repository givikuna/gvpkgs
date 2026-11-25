{
  description = "gvpkgs: Unstable Packages Repository";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    mk-script.url = "github:givikuna/nix-mkScript";
  };

  outputs =
    {
      self,
      nixpkgs,
      fenix,
      mk-script,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        import ./pkgs {
          inherit nixpkgs fenix system;
        }
      );

      checks = forAllSystems (
        system:
        import ./nixpkgs/tests {
          inherit nixpkgs system;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          mkScript = mk-script.lib.mkScript pkgs { };
        in
        {
          default = pkgs.mkShell {
            packages = [
              (mkScript "gvpkgs-build" "scripts/gvpkgs-build.elv")
              (mkScript "gvpkgs-check-build" "scripts/gvpkgs-check-build.elv")
              (mkScript "gvpkgs-check" "scripts/gvpkgs-check.elv")
              (mkScript "gvpkgs-run" "scripts/gvpkgs-run.elv")
              (mkScript "gvpkgs-nixpkgs-build" "scripts/gvpkgs-nixpkgs-build.elv")
              (mkScript "gvpkgs-list" "scripts/gvpkgs-list.elv")
              (mkScript "gvpkgs-new" "scripts/gvpkgs-new.elv")
              (mkScript "gvpkgs-promote" "scripts/gvpkgs-promote.elv")
            ];
          };
        }
      );
    };
}
