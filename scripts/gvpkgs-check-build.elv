use str

var default-system = x86_64-linux
var supported-systems = [x86_64-linux aarch64-linux aarch64-darwin]

fn usage {
    echo 'Usage: gvpkgs-check-build <check-name> [system] [nix-build-args...]

Build a staged package or test under `.#checks.<system>.<check-name>`.
Defaults to `x86_64-linux` if no system is provided.

Supported systems:
    x86_64-linux, aarch64-linux, aarch64-darwin

Examples:
    gvpkgs-check-build fregec
    gvpkgs-check-build fregec-test-hello aarch64-linux
    gvpkgs-check-build fregec --show-trace

Options:
    -h, --help    Show this help message and exit'
}

if (and (> (count $args) 0) (or (eq $args[0] -h) (eq $args[0] --help))) {
    usage
    exit 0
}

if (< (count $args) 1) {
    echo 'Error: missing check or package name.' >&2
    usage >&2
    exit 1
}

var name = $args[0]
var system = $default-system
var extra = []

if (> (count $args) 1) {
    if (str:has-prefix $args[1] -) {
        set extra = $args[1..]
    } else {
        set system = $args[1]
        set extra = $args[2..]
    }
}

if (not (has-value $supported-systems $system)) {
    echo 'Error: unsupported system "'$system'".' >&2
    echo 'Supported: '(str:join ', ' $supported-systems) >&2
    exit 1
}

nix build '.#checks.'$system'.'$name $@extra
