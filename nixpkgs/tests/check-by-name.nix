{
  pkgs,
  byNamePkgNames,
  byNameDir,
}:
let
  inherit (pkgs) lib;

  allowedTopFiles = [
    "README.md"
    ".keep"
  ];

  topEntries = builtins.readDir byNameDir;

  topErrors = lib.concatLists (
    lib.mapAttrsToList (
      name: type:
      if type == "directory" then
        if builtins.stringLength name < 1 || builtins.stringLength name > 2 || name != lib.toLower name then
          [ "pkgs/by-name/${name}: shard directory must be 1-2 lowercase characters" ]
        else
          [ ]
      else if builtins.elem name allowedTopFiles then
        [ ]
      else
        [ "pkgs/by-name/${name}: unexpected non-directory entry" ]
    ) topEntries
  );

  shardDirs = lib.filterAttrs (_: type: type == "directory") topEntries;

  packageDirErrors = lib.concatLists (
    lib.mapAttrsToList (
      shard: _:
      let
        shardPath = byNameDir + "/${shard}";
        shardEntries = builtins.readDir shardPath;
      in
      lib.concatLists (
        lib.mapAttrsToList (
          name: type:
          if type != "directory" then
            [ "pkgs/by-name/${shard}/${name}: expected a package directory" ]
          else
            let
              expectedShard = builtins.substring 0 2 (lib.toLower name);
              pkgFile = shardPath + "/${name}/package.nix";
            in
            (lib.optional (
              shard != expectedShard
            ) "pkgs/by-name/${shard}/${name}: wrong shard '${shard}', expected '${expectedShard}'")
            ++ (lib.optional (
              !builtins.pathExists pkgFile
            ) "pkgs/by-name/${shard}/${name}: missing package.nix")
        ) shardEntries
      )
    ) shardDirs
  );

  metaErrors = lib.concatLists (
    map (
      name:
      let
        pkg = pkgs.${name};
        meta = pkg.meta or { };
      in
      (lib.optional (!(meta ? description) || meta.description == "") "${name}: missing meta.description")
      ++ (lib.optional (!(meta ? homepage)) "${name}: missing meta.homepage")
      ++ (lib.optional (!(meta ? license)) "${name}: missing meta.license")
      ++ (lib.optional (
        !(meta ? maintainers) || meta.maintainers == [ ]
      ) "${name}: missing meta.maintainers")
    ) byNamePkgNames
  );

  allErrors = topErrors ++ packageDirErrors ++ metaErrors;
in
pkgs.runCommand "nixpkgs-by-name-check" { } (
  if allErrors == [ ] then
    ''
      echo "All nixpkgs/pkgs/by-name checks passed (${toString (builtins.length byNamePkgNames)} package(s))."
      touch $out
    ''
  else
    ''
      cat >&2 <<'EOF'
      nixpkgs/pkgs/by-name validation failed:
      ${lib.concatMapStringsSep "\n" (e: "  - ${e}") allErrors}
      EOF
      exit 1
    ''
)
