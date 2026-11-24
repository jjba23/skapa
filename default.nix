# skapa
#
# SPDX-License-Identifier: MIT
# Copyright © Josep Bigorra <jjbigorra@gmail.com>

{ lib
, stdenv
, guile
, makeWrapper
, coreutils
, util-linux
, bash
, guile-json
, guile-scriba ? null
}:

stdenv.mkDerivation {
  pname = "skapa";
  version = "0.0.19";

  src = ./.;

  nativeBuildInputs = [
    guile
    makeWrapper
  ];

  buildInputs = [
    guile
    guile-json
    coreutils
    util-linux
    bash
  ] ++ lib.optional (guile-scriba != null) guile-scriba;

  buildPhase = ''
    runHook preBuild

    # Create destination module directories
    mkdir -p share/guile/site/3.0
    mkdir -p lib/guile/3.0/site-ccache

    # Copy raw Scheme source files
    cp -r src/skapa share/guile/site/3.0/

    # Compile Scheme sources to bytecode (.go files)
    for file in src/skapa/*.scm; do
      filename=$(basename "$file")
      target="lib/guile/3.0/site-ccache/skapa/''${filename%.scm}.go"
      mkdir -p "$(dirname "$target")"
      guild compile \
        -L src \
        -o "$target" \
        "$file"
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share

    # Install Guile module files
    cp -r share $out/
    cp -r lib $out/

    # Install static resources (templates, licenses, help text)
    mkdir -p $out/share/resources
    cp resources/help.txt $out/share/resources/
    cp -r resources/templates $out/share/resources/
    cp -r resources/licenses $out/share/resources/

    # Install the CLI script
    cp scripts/skapa $out/bin/skapa
    chmod +x $out/bin/skapa

    # Patch core system tool invocations inside scripts/skapa
    substituteInPlace $out/bin/skapa \
      --replace-quiet "readlink " "${coreutils}/bin/readlink " \
      --replace-quiet "readlink " "${bash}/bin/bash " \
      --replace-quiet "realpath " "${coreutils}/bin/realpath " \
      --replace-quiet "dirname " "${coreutils}/bin/dirname " \
      --replace-quiet "getopt " "${util-linux}/bin/getopt " \
      --replace-quiet "exec guile " "exec ${guile}/bin/guile "

    runHook postInstall
  '';

  postFixup = ''
    # Wrap executable to ensure GUILE_LOAD_PATH includes dependency modules
    wrapProgram $out/bin/skapa \
      --prefix GUILE_LOAD_PATH : "$out/share/guile/site/3.0:$GUILE_LOAD_PATH" \
      --prefix GUILE_LOAD_COMPILED_PATH : "$out/lib/guile/3.0/site-ccache:$GUILE_LOAD_COMPILED_PATH"
  '';

  meta = with lib; {
    description = "Interactive CLI wizard project scaffolder written in Guile Scheme";
    homepage = "https://github.com/jjba23/skapa";
    license = licenses.mit;
    mainProgram = "skapa";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
