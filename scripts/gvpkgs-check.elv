fn usage {
    echo 'Usage: gvpkgs-check [nix-flake-check-args...]

Run `nix flake check` for this repository.

Options:
    -h, --help    Show this help message and exit'
}

if (and (> (count $args) 0) (or (eq $args[0] -h) (eq $args[0] --help))) {
    usage
    exit 0
}

nix flake check $@args
