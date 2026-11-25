use os
use path

fn usage {
    echo 'Usage: gvpkgs-list

List all packages in ./pkgs and staged packages in ./nixpkgs/pkgs/by-name.

Options:
    -h, --help    Show this help message and exit'
}

for arg $args {
    if (or (eq $arg -h) (eq $arg --help)) {
        usage
        exit 0
    }
}

echo 'gvpkgs (./pkgs):'
for dir [pkgs/*[nomatch-ok]] {
    if (and (os:is-dir $dir) (os:exists (path:join $dir package.nix))) {
        echo '  - '(path:base $dir)
    }
}

echo ''
echo 'nixpkgs staging (./nixpkgs/pkgs/by-name):'
for shard [nixpkgs/pkgs/by-name/*[nomatch-ok]] {
    if (os:is-dir $shard) {
        for dir [$shard/*[nomatch-ok]] {
            if (and (os:is-dir $dir) (os:exists (path:join $dir package.nix))) {
                echo '  - '(path:base $dir)' ('(path:base $shard)'/'(path:base $dir)')'
            }
        }
    }
}
