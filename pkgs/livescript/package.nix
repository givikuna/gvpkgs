{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  stdenvNoCC,
  nodejs,
  cacert,
  makeWrapper,
  runCommand,
  ...
}:
let
  pname = "livescript";
  version = "1.6.1";
  last-npm-version = "1.6.0";

  src = fetchFromGitHub {
    owner = "gkz";
    repo = "LiveScript";
    rev = version;
    hash = "sha256-92ezj294tWfhiETa3AEWjFbMv2NYOQfEykN8DkUtfOU=";
  };

  packageLock = stdenvNoCC.mkDerivation {
    name = "${pname}-${version}-package-lock.json";
    inherit src;
    nativeBuildInputs = [
      nodejs
      cacert
    ];
    buildPhase = ''
      export HOME=$TMPDIR
      npm install --package-lock-only --ignore-scripts --no-audit --no-fund
    '';
    installPhase = ''
      cp package-lock.json $out
    '';
    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = "sha256-rM/xtyyGmD0n/BnMO7HFCIGRgdiMt1esJ3LDyzrixG8=";
  };

  bootstrap = runCommand "${pname}-bootstrap-${last-npm-version}" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/livescript/-/livescript-${last-npm-version}.tgz";
        hash = "sha256-cg0NkRqFNO+t8iLJwm7U/hcu0PZdumZQhcY7CrvEAZo=";
      }
    } -C $out --strip-components=1
    chmod +x $out/bin/lsc
  '';

in
buildNpmPackage {
  inherit pname version src;

  postPatch = ''
    cp ${packageLock} package-lock.json
  '';

  npmDepsHash = "sha256-ofxuJT1qi+aNphbOB93TZaRE2S4drCVO1yqSpHDfGhE=";
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    export NODE_PATH="$PWD/node_modules"

    make LSC="${bootstrap}/bin/lsc" build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/livescript
    cp -r lib bin package.json $out/lib/node_modules/livescript/
    cp -r node_modules $out/lib/node_modules/livescript/node_modules

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node \
      $out/bin/lsc \
      --add-flags "$out/lib/node_modules/livescript/bin/lsc"

    runHook postInstall
  '';

  meta = {
    description = "LiveScript is a language which compiles to JavaScript";
    homepage = "https://livescript.net";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ givikuna ];
    mainProgram = "lsc";
    platforms = lib.platforms.unix;
  };
}
