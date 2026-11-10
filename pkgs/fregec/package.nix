{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  jdk11_headless,
  byacc,
  perl,
  makeBinaryWrapper,
  ...
}:

let
  bootstrapJar = fetchurl {
    url = "https://github.com/Frege/frege/releases/download/3.25alpha/frege3.25.84.jar";
    hash = "sha256-ZsYAB9WjZh74Mw/8DHddIJn8qzXuS0CHYSuVpu4YHPM=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "fregec";
  version = "3.25.84-unstable-2023-07-02";

  src = fetchFromGitHub {
    owner = "Frege";
    repo = "frege";
    rev = "master";
    hash = "sha256-9fxoWKtpBTKm4twU6k3/Ns1cdZuCOetofZ6Q+UlCEdo=";
  };

  nativeBuildInputs = [
    jdk11_headless
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

    make JAVA="${jdk11_headless}/bin/java -Dfrege.javac=internal" \
         JAVAC="${jdk11_headless}/bin/javac -encoding UTF-8" \
         YACC="${lib.getExe' byacc "byacc"}" \
         TIME="" \
         runtime compiler

    ${jdk11_headless}/bin/java -Dfrege.javac=internal \
      -Xss4m -Xmx2222m -cp build \
      frege.compiler.Main -d build -hints -O -target 1.8 \
      -make frege/StandardLibrary.fr

    ${jdk11_headless}/bin/jar -cf fregec.jar -C build frege
    ${jdk11_headless}/bin/jar -uvfe fregec.jar frege.compiler.Main

    runHook postBuild
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    rm -rf build/test
    mkdir -p build/test
    ${jdk11_headless}/bin/java -Dfrege.javac=internal \
      -Xss4m -Xmx2222m -cp build \
      frege.compiler.Main -d build -hints -O -target 1.8 \
      -d build/test -fp build/test -make tests/qc
    ${jdk11_headless}/bin/java \
      -Xss4m -cp build:build/test \
      frege.tools.Quick -v build/test

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 fregec.jar $out/share/java/fregec.jar

    makeWrapper ${jdk11_headless}/bin/java $out/bin/fregec \
      --add-flags "-Xss4m -Xmx2g -Dfrege.javac=internal -jar $out/share/java/fregec.jar"

    runHook postInstall
  '';

  meta = {
    description = "Compiler for Frege.";
    homepage = "https://github.com/Frege/frege";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ givikuna ];
    mainProgram = "fregec";
    platforms = jdk11_headless.meta.platforms;
  };
})
