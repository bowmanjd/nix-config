{ lib, stdenv, fetchurl, autoPatchelfHook, pkgs, ... }:
stdenv.mkDerivation rec {
  pname = "ms-sqltoolsservice";
  #version = "4.5.0.15";
  version = "4.11.0.10";
  dotnet_version = "7.0";

  dontUnpack = true;

  buildInputs = with pkgs; [
    stdenv.cc.cc
    zlib
    curl
    openssl
    lttng-ust
    icu
    libkrb5
  ];

  dontStrip = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  #dontAutoPatchelf = true;

  autoPatchelfIgnoreMissingDeps = [
    "libcrypto.so.10"
    "libssl.so.10"
  ];


  src = fetchurl {
    url = "https://github.com/microsoft/sqltoolsservice/releases/download/${version}/Microsoft.SqlTools.ServiceLayer-rhel-x64-net${dotnet_version}.tar.gz";
    #hash = "sha256-GQ2OaH+I23vNsyedC5jI7FaUgawWqcj2VEKCuMC+Zek=";
    hash = "sha256-hdNZzJLYNO8QKId1q8wqrLLOhE3Wtgmk89vcOD5Ya/A=";
  };

  installPhase = ''
    mkdir -p $out/bin
    tar -x -C $out/bin -f $src
  '';

  postFixup = ''
    patchelf \
      --add-needed libicui18n.so \
      --add-needed libicuuc.so \
      $out/bin/libcoreclr.so \
      $out/bin/*System.Globalization.Native.so
    patchelf \
      --add-needed libgssapi_krb5.so \
      $out/bin/*System.Net.Security.Native.so
    patchelf --replace-needed liblttng-ust.so.0 liblttng-ust.so $out/bin/libcoreclrtraceptprovider.so
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
