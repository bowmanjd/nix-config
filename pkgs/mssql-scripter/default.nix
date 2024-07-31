{ lib, pkgs, python3, fetchFromGitHub, ... }:
python3.pkgs.buildPythonPackage rec {
  pname = "mssql-scripter";
  version = "v1.0.0a23";

  ms-sqltoolsservice = pkgs.callPackage ../ms-sqltoolsservice { };

  propagatedBuildInputs = with python3.pkgs; [
    future
    wheel
  ];

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "mssql-scripter";
    rev = "HEAD";
    hash = "sha256-sabuoIgdrndcf5LVFfDpA/T0hQsAmmLRwo+jpd0/lYU=";
  };

  patchPhase = ''
    patchShebangs mssql-scripter
    substituteInPlace mssqlscripter/main.py \
      --replace "utf-8" "utf-16"
  '';

  postFixup = ''
    wrapProgram "$out/bin/mssql-scripter" \
      --set MSSQLTOOLSSERVICE_PATH ${lib.makeBinPath [ ms-sqltoolsservice ]} \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --prefix PATH : ${lib.makeBinPath [ python3 ]} \
  '';
  
  doCheck = false;

  pythonImportsCheck = [
    "mssqlscripter"
  ];

}
