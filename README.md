# gvpkgs

Simple Nix package repository for testing before merging into Nixpkgs

This repository includes various packages either not yet available in Nixpkgs, or at a newer version than in Nixpkgs.

## Stability Note

Many of the packages in this repository are stable.
However, some are not, as they are being used for testing.

As such, please read the documentation for each package (in the README) on which package is stable and which is not.

Generally, it is recommended to wait until packages are merged into `Nixpkgs` to use them, rather than relying on `gvpkgs`.

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

## Packages

| Package         | Description                                                                                               | Status  |
| --------------- | --------------------------------------------------------------------------------------------------------- | ------- |
| `fregec`        | Compiler for [Frege](https://github.com/Frege/frege), a Haskell-like pure functional language for the JVM | Stable  |
| `moonscript`    | [MoonScript](https://moonscript.org/), a dynamic scripting language that compiles to Lua                  | Stable  |
| `rust-analyzer` | [rust-analyzer](https://rust-analyzer.github.io/), Rust language server                                   | Stable  |
| `ballerina`     | [ballerina](https://ballerina.io/), the programming language compiler, latest version.                    | Testing |
| `livescript`    | [livescript](https://livescript.net/), livescript compiler, latest version.                               | Stable  |

## Nixpkgs Staging (Tests Only)

Upstream-bound packages structured to mirror real `nixpkgs` (`pkgs/by-name` + `maintainers/maintainer-list.nix`).
These are exposed only under `checks` in `flake.nix`, not under `packages`.

### Adding a Package

1. Create `nixpkgs/pkgs/by-name/<first-two-chars>/<name>/package.nix`.
2. Stage new files with `git add nixpkgs/` so Nix flakes can see them.

### Testing

Just follow this:

```bash
nix flake check

nix build .#checks.x86_64-linux.fregec
nix build .#checks.x86_64-linux.fregec-test-hello

nix-build ./nixpkgs -A fregec
nix-build ./nixpkgs -A fregec.tests.hello
```

### Testing Workflow

After creating the files, stage them (`git add .`) so flake evaluation sees them, then run:

- **`nix flake check`** — validates `pkgs/by-name` sharding and `meta`, builds every package in `nixpkgs/pkgs/by-name`, and executes all `passthru.tests.*`.
- **`nix build .#checks.<system>.<pkg>`** — builds one staged package in isolation.
- **`nix-build ./nixpkgs -A <pkg>` / `-A <pkg>.tests.<name>`** — mirrors the exact commands you will run once you copy `pkgs/by-name/<sh>/<name>/package.nix` into a real `nixpkgs` clone.

## Platforms

Supports `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`.
