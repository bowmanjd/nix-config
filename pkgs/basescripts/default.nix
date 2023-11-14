{ lib, stdenv, ... }:

stdenv.mkDerivation {
  pname = "base-scripts";
  version = "1.0";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp scripts/* $out/bin
    chmod +x $out/bin/*
  '';

  meta = {
    description = "Various scripts for surviving and thriving";
    license = lib.licenses.asl20;
    maintainers = [ {
      email = "git@bowmanjd.org";
      github = "bowmanjd";
      githubId = 86415;
      name = "Jonathan Bowman";
    } ];
  };
}
