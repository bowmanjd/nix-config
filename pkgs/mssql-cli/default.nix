{ lib, python311, conftest, fetchFromGitHub }:
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
    pygments
    pyyaml
    sqlparse
    wheel
  ];

  checkInputs = [
    conftest
    (python311.withPackages (ps:
      with ps; [
      setuptools
      coverage
      pytest-cov
      pytest-timeout
      mock
      twine
      tox
      jinja2
      diff-cover
      appdirs
      hypothesis
      pylint
      regex
      twine
      flake8
      tblib
      tqdm
      pathspec
      pytest
      wrapt
      packaging
      six
    ]))
  ];

  src = fetchFromGitHub {
    owner = "bowmanjd";
    repo = "mssql-cli";
    rev = "HEAD";
    hash = "sha256-kUc3y9OlaQ72MsESrVd+eqm4xulFixYMKAIMeP3+NOc=";
  };

  checkPhase = ''
    #runHook preCheck

    #pytest

    #runHook postCheck
  '';

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
