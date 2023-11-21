{ lib, python311 }:
with python3Packages;
python311.pkgs.buildPythonApplication rec {
  pname = "mssql-cli";
  version = "1.0";

  #propagatedBuildInputs = [ flask ];

  src = fetchFromGitHub {
    owner = bowmanjd;
    repo = mssql-cli;
    hash = "sha256-kUc3y9OlaQ72MsESrVd+eqm4xulFixYMKAIMeP3+NOc=";
  };
}
