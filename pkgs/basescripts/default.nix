{ lib, pkgs, stdenv, ... }:

stdenv.mkDerivation {
  pname = "basescripts";
  version = "1.0";

  dontUnpack = true;

  src = ./scripts;

  propagatedBuildInputs = with pkgs; [
    coreutils
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/* $out/bin/
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
