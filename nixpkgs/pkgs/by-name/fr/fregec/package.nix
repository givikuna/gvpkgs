{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  jdk11_headless,
  byacc,
  perl,
  makeBinaryWrapper,
  runCommand,
}:

let
  bootstrapJar = fetchurl {
    url = "https://github.com/Frege/frege/releases/download/3.25alpha/frege3.25.84.jar";
    hash = "sha256-ZsYAB9WjZh74Mw/8DHddIJn8qzXuS0CHYSuVpu4YHPM=";
  };

  jdk = jdk11_headless;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "fregec";
  version = "3.25.84-unstable-2023-07-02";

  src = fetchFromGitHub {
    owner = "Frege";
    repo = "frege";
    rev = "<REPLACE_WITH_COMMIT_SHA>";
    hash = "sha256-9fxoWKtpBTKm4twU6k3/Ns1cdZuCOetofZ6Q+UlCEdo=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    jdk
    byacc
    perl
    makeBinaryWrapper
  ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail "frege/Version.fr: .git/index" "frege/Version.fr:"

    if [ -f scripts/mkversion.pl ]; then
      substituteInPlace scripts/mkversion.pl \
        --replace-quiet '`git describe --tags --always`' '"${finalAttrs.version}"' \
        --replace-quiet '`git describe`' '"${finalAttrs.version}"'
    fi
  '';

  preBuild = ''
    cp ${bootstrapJar} fregec.jar
    chmod +w fregec.jar
  '';

  buildPhase = ''
    runHook preBuild

    make \
      JAVA="${lib.getExe' jdk "java"} -Dfrege.javac=internal" \
      JAVAC="${lib.getExe' jdk "javac"} -encoding UTF-8" \
      YACC="${lib.getExe' byacc "byacc"}" \
      TIME="" \
      runtime compiler

    ${lib.getExe' jdk "java"} -Dfrege.javac=internal \
      -Xss4m -Xmx2222m -cp build \
      frege.compiler.Main -d build -hints -O -target 1.8 \
      -make frege/StandardLibrary.fr

    ${lib.getExe' jdk "jar"} -cf fregec.jar -C build frege
    ${lib.getExe' jdk "jar"} -uvfe fregec.jar frege.compiler.Main

    runHook postBuild
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    rm -rf build/test
    mkdir -p build/test
    ${lib.getExe' jdk "java"} -Dfrege.javac=internal \
      -Xss4m -Xmx2222m -cp build \
      frege.compiler.Main -d build -hints -O -target 1.8 \
      -d build/test -fp build/test -make tests/qc
    ${lib.getExe' jdk "java"} \
      -Xss4m -cp build:build/test \
      frege.tools.Quick -v build/test

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 fregec.jar $out/share/java/fregec.jar

    makeWrapper ${lib.getExe' jdk "java"} $out/bin/fregec \
      --add-flags "-Xss4m -Xmx2g -Dfrege.javac=internal -jar $out/share/java/fregec.jar"

    runHook postInstall
  '';

  passthru.tests.hello = runCommand "${finalAttrs.pname}-test-hello" { } ''
    cat > Hello.fr <<'EOF'
    module Hello where
    main _ = println "Hello, World!"
    EOF
    ${lib.getExe finalAttrs.finalPackage} -d . Hello.fr
    output=$(${lib.getExe' jdk "java"} -cp ".:${finalAttrs.finalPackage}/share/java/fregec.jar" Hello)
    [[ "$output" == "Hello, World!" ]]
    touch $out
  '';

  meta = {
    description = "Compiler for Frege, a Haskell-like pure functional language for the JVM";
    homepage = "https://github.com/Frege/frege";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ givikuna ];
    mainProgram = "fregec";
    platforms = jdk.meta.platforms;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode
    ];
  };
})
