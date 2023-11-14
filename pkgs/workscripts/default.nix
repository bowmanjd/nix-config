{ lib, stdenv, ... }:

stdenv.mkDerivation {
  pname = "workscripts";
  version = "1.0";

  dontUnpack = true;

  src = ./scripts;

  installPhase = ''
    mkdir -p $out/bin
    cp $src/* $out/bin/
    chmod +x $out/bin/*
  '';

  meta = {
    description = "Various scripts for surviving and thriving at work";
    license = lib.licenses.asl20;
    maintainers = [ {
      email = "git@bowmanjd.org";
      github = "bowmanjd";
      githubId = 86415;
      name = "Jonathan Bowman";
    } ];
  };
}
