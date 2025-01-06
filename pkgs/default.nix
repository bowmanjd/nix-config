# build using 'nix build .#basescripts'
{ pkgs ? import <nixpkgs> { }, ... }: rec {
  basescripts = pkgs.callPackage ./basescripts { };
  harlequin-odbc = pkgs.callPackage ./harlequin-odbc { };
  workscripts = pkgs.callPackage ./workscripts { };
  mssql-bcp = pkgs.callPackage ./mssql-bcp { };
  ms-sqltoolsservice = pkgs.callPackage ./ms-sqltoolsservice { };
  mssql-cli = pkgs.callPackage ./mssql-cli { };
  mssql-scripter = pkgs.callPackage ./mssql-scripter { };
}
