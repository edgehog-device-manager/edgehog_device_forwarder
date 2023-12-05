# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

{ stdenvNoCC, sd, ripgrep }:
stdenvNoCC.mkDerivation {
  pname = "update_copyright";
  version = "0.0.1";
  src = ./.;

  nativeBuildInputs = [ sd ripgrep ];

  noBuild = true;

  installPhase = ''
    runHook preInstall
    install -m 755 -D ./update_copyright.sh $out/bin/update_copyright
    runHook postInstall
  '';
}
