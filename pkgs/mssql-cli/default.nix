{ lib, python311, fetchFromGitHub }:
python311.pkgs.buildPythonApplication rec {
  pname = "mssql-cli";
  version = "1.0";

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
  ];

  src = fetchFromGitHub {
    owner = "bowmanjd";
    repo = "mssql-cli";
    rev = "HEAD";
    hash = "sha256-xvOaCUvgzX8mAeQ4Ic3eGjvCFAhS8Uxh68ibXNEYZEM=";
  };

  checkPhase = ''
    #runHook preCheck

    #pytest

    #runHook postCheck
  '';
  pythonImportsCheck = [
    "mssqlcli"
  ];

  meta = {
    description = "mssql-cli interactive command-line tool for querying SQL Server";
    license = lib.licenses.bsd3;
    maintainers = [ {
      email = "git@bowmanjd.org";
      github = "bowmanjd";
      githubId = 86415;
      name = "Jonathan Bowman";
    } ];
  };
}
