# build using 'nix build .#basescripts'
{ pkgs ? import <nixpkgs> { }, ... }: rec {
  basescripts = pkgs.callPackage ./basescripts { };
  workscripts = pkgs.callPackage ./workscripts { };
  mssql-bcp = pkgs.callPackage ./mssql-bcp { };
  ms-sqltoolsservice = pkgs.callPackage ./ms-sqltoolsservice { };
}
