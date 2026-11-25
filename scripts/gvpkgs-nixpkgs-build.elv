fn usage {
    echo 'Usage: gvpkgs-nixpkgs-build <attr> [nix-build-args...]

Build an attribute from ./nixpkgs using `nix-build ./nixpkgs -A <attr>`.

Examples:
    gvpkgs-nixpkgs-build fregec
    gvpkgs-nixpkgs-build fregec.tests.hello

Options:
    -h, --help    Show this help message and exit'
}

if (and (> (count $args) 0) (or (eq $args[0] -h) (eq $args[0] --help))) {
    usage
    exit 0
}

if (< (count $args) 1) {
    echo 'Error: missing attribute name.' >&2
    usage >&2
    exit 1
}

var attr = $args[0]
var extra = $args[1..]

nix-build ./nixpkgs -A $attr $@extra
