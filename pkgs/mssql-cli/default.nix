{ lib, pkgs, python311, fetchFromGitHub, ... }:
python311.pkgs.buildPythonPackage rec {
  pname = "mssql-cli";
  version = "1.0";

  ms-sqltoolsservice = pkgs.callPackage ../ms-sqltoolsservice { };

  propagatedBuildInputs = with python311.pkgs; [
    applicationinsights
    cli-helpers
    click
    configobj
    future
    humanize
    prompt-toolkit
    sqlparse
    wheel
    pygments
  ];

  src = fetchFromGitHub {
    owner = "dbcli";
    repo = "mssql-cli";
    rev = "HEAD";
    hash = "sha256-XB+r8FW81oJ5h86LN1gkbOaN2s7QyVIW98YgDQQzH50=";
  };

  postFixup = ''
    wrapProgram "$out/bin/mssql-cli" \
      --set MSSQLTOOLSSERVICE_PATH ${lib.makeBinPath [ ms-sqltoolsservice ]} \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --prefix PATH : ${lib.makeBinPath [ python311 ]} \
  '';
  
  doCheck = false;

  pythonImportsCheck = [
    "mssqlcli"
  ];

}
