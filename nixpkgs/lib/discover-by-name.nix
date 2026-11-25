{ lib }:
baseDirectory:
let
  entries = builtins.readDir baseDirectory;
  shardDirs = lib.filterAttrs (_: type: type == "directory") entries;

  readShard =
    shard: _:
    let
      shardPath = baseDirectory + "/${shard}";
      pkgDirs = lib.filterAttrs (
        name: type: type == "directory" && builtins.pathExists (shardPath + "/${name}/package.nix")
      ) (builtins.readDir shardPath);
    in
    lib.mapAttrs (name: _: {
      inherit name shard;
      dir = shardPath + "/${name}";
      file = shardPath + "/${name}/package.nix";
    }) pkgDirs;
in
lib.foldl' (acc: shard: acc // readShard shard null) { } (builtins.attrNames shardDirs)
