{ lib, stdenv, fetchurl, ... }:

stdenv.mkDerivation rec {
  pname = "ms-sqltoolsservice";
  version = "4.5.0.15";

  dontUnpack = true;

  src = fetchurl {
    url = "https://github.com/microsoft/sqltoolsservice/releases/download/${version}/Microsoft.SqlTools.ServiceLayer-rhel-x64-net6.0.tar.gz";
    hash = "sha256-GQ2OaH+I23vNsyedC5jI7FaUgawWqcj2VEKCuMC+Zek=";
  };

  installPhase = ''
    mkdir -p $out
    cd $out
    tar xf $src
  '';

  meta = {
    description = "Microsoft SQL Tools API service that provides SQL Server data management capabilities";
    license = lib.licenses.mit;
    maintainers = [ {
      email = "git@bowmanjd.org";
      github = "bowmanjd";
      githubId = 86415;
      name = "Jonathan Bowman";
    } ];
  };
}
