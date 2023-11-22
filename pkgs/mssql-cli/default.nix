{ lib, python311, fetchFromGitHub }:
python311.pkgs.buildPythonPackage rec {
  pname = "mssql-cli";
  version = "1.0";

  nativeBuildInputs = [ python311.pkgs.wrapPython ];
  
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
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --prefix PATH : "${python311}/bin"
  '';
  
  doCheck = false;

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
