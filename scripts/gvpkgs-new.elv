use os
use path
use str

fn usage {
    echo 'Usage: gvpkgs-new <pkgs|nixpkgs> <name>

Scaffold a new package.nix in ./pkgs/<name> or ./nixpkgs/pkgs/by-name/<shard>/<name>,
then register it with `git add -N` so Nix flakes can evaluate it immediately.

Options:
  -h, --help    Show this help message and exit'
}

for arg $args {
    if (or (eq $arg -h) (eq $arg --help)) {
        usage
        exit 0
    }
}

if (!= (count $args) 2) {
    echo 'Error: expected target (pkgs or nixpkgs) and package name.' >&2
    usage >&2
    exit 1
}

var target = $args[0]
var name = $args[1]
var pkg-dir = ''

if (eq $target pkgs) {
    set pkg-dir = (path:join pkgs $name)
} elif (eq $target nixpkgs) {
    var lower = (str:to-lower $name)
    var shard = $lower
    if (> (count $lower) 2) {
        set shard = $lower[0..2]
    }
    set pkg-dir = (path:join nixpkgs pkgs by-name $shard $name)
} else {
    echo 'Error: target must be "pkgs" or "nixpkgs", got "'$target'".' >&2
    exit 1
}

var pkg-file = (path:join $pkg-dir package.nix)

if (os:exists $pkg-file) {
    echo 'Error: '$pkg-file' already exists.' >&2
    exit 1
}

os:mkdir-all $pkg-dir

var template = '{
    lib,
    stdenv,
    fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
    pname = "'$name'";
    version = "0.0.0";

    src = fetchFromGitHub {
        owner = "";
        repo = "";
        rev = "v${finalAttrs.version}";
        hash = "";
    };

    meta = {
        description = "";
        homepage = "";
        license = lib.licenses.mit;
        maintainers = with lib.maintainers; [ givikuna ];
        mainProgram = "'$name'";
        platforms = lib.platforms.unix;
    };
})
'

print $template > $pkg-file
git add -N $pkg-file
echo 'Created '$pkg-file' (tracked with git add -N).'
