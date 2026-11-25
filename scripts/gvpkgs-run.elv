use os
use path

fn usage {
  echo 'Usage: gvpkgs-run <package> [program-args...]

Run a package defined in ./pkgs using `nix run .#<package>`.

Options:
    -h, --help    Show this help message and exit'
}

if (and (> (count $args) 0) (or (eq $args[0] -h) (eq $args[0] --help))) {
    usage
    exit 0
}

if (< (count $args) 1) {
    echo 'Error: missing package name.' >&2
    usage >&2
    exit 1
}

var pkg = $args[0]
var prog-args = $args[1..]
var pkg-file = (path:join pkgs $pkg package.nix)

if (not (os:exists $pkg-file)) {
  echo 'Error: package "'$pkg'" not found at '$pkg-file >&2
  exit 1
}

nix run '.#'$pkg -- $@prog-args
