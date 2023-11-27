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
    hash = "sha256-YPckb4TDK+hN4U4Hac03JgbxkoU9qN/sg3CBZygFnU8=";
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
      --prefix PATH : ${lib.makeBinPath [ python311 ]} \
  '';
  
  doCheck = false;

  pythonImportsCheck = [
    "mssqlscripter"
  ];

}
