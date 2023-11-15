# build using 'nix build .#basescripts'
{ pkgs ? import <nixpkgs> { }, ... }: rec {
  basescripts = pkgs.callPackage ./basescripts { };
  workscripts = pkgs.callPackage ./workscripts { };
  mssql-tools18 = pkgs.callPackage ./mssql-tools18 { };
}
