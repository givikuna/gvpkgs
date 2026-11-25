{
  ballerina,
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  openjdk17_headless,
  writeText,
  runCommand,
  ...
}:
let
  version = "2201.14.2";
  codeName = "swan-lake";
  openjdk = openjdk17_headless;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ballerina";
  inherit version;

  src = fetchzip {
    url = "https://dist.ballerina.io/downloads/${version}/ballerina-${version}-${codeName}.zip";
    hash = "sha256-JVwxWRiOQaUZBkvxoLhKvktyQYnBtbCBZXZa6g6hoRQ=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -rv ./* $out/
    runHook postInstall
  '';
  preFixup = ''
    wrapProgram $out/bin/bal --set JAVA_HOME ${openjdk}
  '';

  passthru.tests.smokeTest =
    let
      helloWorld = writeText "hello-world.bal" ''
        import ballerina/io;
        public function main() {
          io:println("Hello, World!");
        }
      '';
    in
    runCommand "ballerina-${version}-smoketest" { } ''
      ${ballerina}/bin/bal run ${helloWorld} >$out
      read result <$out
      [[ $result = "Hello, World!" ]]
    '';

  meta = {
    description = "Open-source programming language for the cloud.";
    mainProgram = "bal";
    homepage = "https://ballerina.io/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ givikuna ];
    platforms = openjdk.meta.platforms;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
  };
})
