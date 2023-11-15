{ lib, stdenv, ... }:
let version = "18.2.1.1-1";
in
stdenv.mkDerivation {
  pname = "mssql-tools18";

  src = nixpkgs.fetchurl {
    url = "https://packages.microsoft.com/debian/11/prod/pool/main/m/mssql-tools18/mssql-tools18_${version}_amd64.deb";
    sha256 = "70f219b0d7a4d4a9ff3596164a9018bf5bbc61d4313c83186010f81b3f292218";
  };

  unpackPhase = ''
      dpkg -x $src ./
    '';
  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp opt/mssql-tools18/bin/bcp $out/bin/bcp
    cp -r opt/mssql-tools18/share $out/
    mkdir -p $out/bin
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

