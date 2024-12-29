{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  pkgs,
  ...
}:
stdenv.mkDerivation rec {
  pname = "ms-sqltoolsservice";
  #version = "4.11.0.10";
  version = "5.0.20241218.1";
  #dotnet_version = "7.0";
  dotnet_version = "8.0";

  buildInputs = with pkgs; [
    stdenv.cc.cc
    zlib
    curl
    openssl
    lttng-ust
    icu
    libkrb5
  ];

  dontUnpack = true;

  # Don't strip, as it results in "Failed to create CoreCLR, HRESULT: 0x80004005"
  dontStrip = true;

  nativeBuildInputs = [autoPatchelfHook];

  autoPatchelfIgnoreMissingDeps = [
    "libcrypto.so.10"
    "libssl.so.10"
  ];

  src = fetchurl {
    #url = "https://github.com/microsoft/sqltoolsservice/releases/download/${version}/Microsoft.SqlTools.ServiceLayer-rhel-x64-net${dotnet_version}.tar.gz";
    url = "https://github.com/microsoft/sqltoolsservice/releases/download/${version}/Microsoft.SqlTools.ServiceLayer-linux-x64-net${dotnet_version}.tar.gz";
    #hash = "sha256-hdNZzJLYNO8QKId1q8wqrLLOhE3Wtgmk89vcOD5Ya/A=";
    hash = "sha256-9vCKxzCISDQiKnE8dTLhSRMCpYo4zTMAiJQ47JPPSE4=";
  };

  installPhase = ''
    mkdir -p $out/bin
    tar -x -C $out/bin -f $src
  '';

  # Need to add icu dependency so autoPatchelfHook can associate required libraries
  # Also follow powershell's example in updating lttng-ust
  # And add needed modern ssl
  postFixup = ''
    patchelf \
      --add-needed libicui18n.so \
      --add-needed libicuuc.so \
      $out/bin/libcoreclr.so \
      $out/bin/*System.Globalization.Native.so
    patchelf \
      --replace-needed liblttng-ust.so.0 liblttng-ust.so \
      $out/bin/libcoreclrtraceptprovider.so
    patchelf \
      --add-needed libgssapi_krb5.so \
      $out/bin/*System.Net.Security.Native.so
    patchelf --add-needed libssl.so \
             $out/bin/*System.Security.Cryptography.Native.OpenSsl.so
    chmod 444 $out/bin/System.Runtime.dll
  '';

  meta = {
    description = "Microsoft SQL Tools API service that provides SQL Server data management capabilities";
    license = lib.licenses.mit;
    maintainers = [
      {
        email = "git@bowmanjd.org";
        github = "bowmanjd";
        githubId = 86415;
        name = "Jonathan Bowman";
      }
    ];
  };
}
