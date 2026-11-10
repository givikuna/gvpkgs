# gvpkgs

Simple Nix package repository for testing before merging into Nixpkgs

This repository includes various packages either not yet available in Nixpkgs, or at a newer version than in Nixpkgs.

## Stability Note

Many of the packages in this repository are stable.
However, some are not, as they are being used for testing.

As such, please read the documentation for each package (in the README) on which package is stable and which is not.

Generally, it is recommended to wait until packages are merged into `Nixpkgs` to use them, rather than relying on `gvpkgs`.

## Packages

| Package         | Description                                                                                               | Status  |
| --------------- | --------------------------------------------------------------------------------------------------------- | ------- |
| `fregec`        | Compiler for [Frege](https://github.com/Frege/frege), a Haskell-like pure functional language for the JVM | Testing |
| `moonscript`    | [MoonScript](https://moonscript.org/), a dynamic scripting language that compiles to Lua                  | Stable  |
| `rust-analyzer` | [rust-analyzer](https://rust-analyzer.github.io/), Rust language server                                   | Stable  |

Supports `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`.

## Usage

Add `gvpkgs` to your flake inputs:

```Nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        gvpkgs.url = "github:givikuna/gvpkgs";
    };

    outputs = { self, nixpkgs, gvpkgs, ... }:
    let
        system = "x86_64-linux";
    in
    {
        nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
                gvpkgs = gvpkgs.packages.${system};
            };
            modules = [ ./configuration.nix ];
        };
    }
}
```

Then in any module you can do:

```Nix
{ gvpkgs, ... }: {
    environment.systemPackages = [
        gvpkgs.fregec
    ];
}
```

### Shell

Use this to enter a shell with a package from here:

```BASH
nix shell github:givikuna/gvpkgs#fregec
```

Use this to run a package from here:

```BASH
nix run github:givikuna/gvpkgs#rust-analyzer
```
