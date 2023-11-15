{ lib, stdenv, fetchurl, dpkg, patchelf, unixODBC, openssl, libkrb5, libuuid, ... }:
let version = "18.2.1.1-1";
in
stdenv.mkDerivation {
  pname = "mssql-tools18";
  name = "mssql-tools18";

  src = fetchurl {
    url = "https://packages.microsoft.com/debian/11/prod/pool/main/m/mssql-tools18/mssql-tools18_${version}_amd64.deb";
    sha256 = "70f219b0d7a4d4a9ff3596164a9018bf5bbc61d4313c83186010f81b3f292218";
  };

  nativeBuildInputs =
    [
      dpkg
      patchelf
    ];

  unpackPhase = ''
      dpkg -x $src ./
    '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r opt/ $out/
    cp opt/mssql-tools18/bin/* $out/bin/
    mkdir -p $out/opt/mssql-tools18/
    cp -r opt/mssql-tools18/share $out/opt/mssql-tools18/
    cp -r opt/mssql-tools18/share $out/
  '';

  postFixup = ''
    patchelf --set-rpath ${lib.makeLibraryPath [ unixODBC openssl libkrb5 libuuid stdenv.cc.cc ]} $out/bin/*
    patchelf --set-rpath ${lib.makeLibraryPath [ unixODBC openssl libkrb5 libuuid stdenv.cc.cc ]} $out/opt/mssql-tools18/bin/*
  '';

  meta = {
    description = "Microsoft SQL Server command-line tool bcp";
    license = lib.licenses.unfree;
    maintainers = [ {
      email = "git@bowmanjd.org";
      github = "bowmanjd";
      githubId = 86415;
      name = "Jonathan Bowman";
    } ];
  };
}

