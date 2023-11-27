{ lib, pkgs, python311, fetchFromGitHub, ... }:
python311.pkgs.buildPythonPackage rec {
  pname = "mssql-scripter";
  version = "v1.0.0a23";

  ms-sqltoolsservice = pkgs.callPackage ../ms-sqltoolsservice { };

  propagatedBuildInputs = with python311.pkgs; [
    future
    wheel
  ];

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "mssql-scripter";
    rev = "HEAD";
    hash = "";
  };

  postFixup = ''
    wrapProgram "$out/bin/mssql-scripter" \
      --set MSSQLTOOLSSERVICE_PATH ${lib.makeBinPath [ ms-sqltoolsservice ]} \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --prefix PATH : ${lib.makeBinPath [ python311 ]} \
  '';
  
  doCheck = false;

  pythonImportsCheck = [
    "mssqlscripter"
  ];

}
