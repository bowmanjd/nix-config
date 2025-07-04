# build using 'nix build .#basescripts'
{ pkgs ? import <nixpkgs> { }, ... }: rec {
  basescripts = pkgs.callPackage ./basescripts { };
  llmscripts = pkgs.callPackage ./llmscripts { };
  # harlequin-odbc = pkgs.callPackage ./harlequin-odbc { };
  # harlequin = pkgs.callPackage ./harlequin { };
  workscripts = pkgs.callPackage ./workscripts { };
  mssql-bcp = pkgs.callPackage ./mssql-bcp { };
  ms-sqltoolsservice = pkgs.callPackage ./ms-sqltoolsservice { };
  mssql-cli = pkgs.callPackage ./mssql-cli { };
  # mssql-scripter = pkgs.callPackage ./mssql-scripter { };
}
