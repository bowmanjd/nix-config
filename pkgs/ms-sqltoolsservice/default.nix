{ lib, stdenv, fetchzip, ... }:

stdenv.mkDerivation rec {
  pname = "ms-sqltoolsservice";
  version = "4.5.0.15";

  dontUnpack = true;

  src = fetchzip {
    url = "https://github.com/microsoft/sqltoolsservice/releases/download/${version}/Microsoft.SqlTools.Migration-rhel-x64-net6.0.tar.gz";
    hash = "sha256-V26R+dJO9LfUQiLgYb/AVzOXNj3Iu5h9cRj9LIUiYqY=";
    stripRoot = false;
  };

  installPhase = ''
    mkdir -p $out/lib
    cp -r $src/* $out/lib/
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
