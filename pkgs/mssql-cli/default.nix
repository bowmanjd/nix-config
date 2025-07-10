{ lib, pkgs, python312, fetchFromGitHub, ... }:
python312.pkgs.buildPythonPackage rec {
  pname = "mssql-cli";
  version = "1.0";
  pyproject = true;
  build-system = [ python312.pkgs.setuptools ];

  ms-sqltoolsservice = pkgs.callPackage ../ms-sqltoolsservice { };

  propagatedBuildInputs = with python312.pkgs; [
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
      --prefix PATH : ${lib.makeBinPath [ python312 ]}
    sed -i "s/utcnow().isoformat() + 'Z'/now(datetime.UTC).isoformat()/" $out/lib/python3*/site-packages/mssqlcli/telemetry_upload.py
  '';
  
  doCheck = false;

  pythonImportsCheck = [
    "mssqlcli"
  ];

}
