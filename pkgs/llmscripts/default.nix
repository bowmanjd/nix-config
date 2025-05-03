{ lib, pkgs, stdenv, ... }:

stdenv.mkDerivation {
  pname = "llmscripts";
  version = "1.0";

  dontUnpack = true;

  src = ./scripts;

  propagatedBuildInputs = with pkgs; [
    coreutils
    bun
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/* $out/bin/
    chmod +x $out/bin/*
  '';

  meta = {
    description = "Scripts for LLM tooling";
    license = lib.licenses.asl20;
    maintainers = [ {
      email = "git@bowmanjd.org";
      github = "bowmanjd";
      githubId = 86415;
      name = "Jonathan Bowman";
    } ];
  };
}
