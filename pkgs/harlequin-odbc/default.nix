{
  lib,
  pkgs,
  python3,
  fetchPypi,
}:
python3.pkgs.buildPythonPackage rec {
  pname = "harlequin-odbc";
  version = "0.1.1";
  pyproject = true;

  src = fetchPypi {
    pname = "harlequin_odbc";
    inherit version;
    hash = "sha256-vrK1eDbM2yG0+ksVHizW/BuUb0+RTrIz3l3rwsCJIM8=";
  };

  build-system = [
    python3.pkgs.poetry-core
  ];

  dependencies = [
    python3.pkgs.pyodbc
    #pkgs.harlequin
  ];

  doCheck = false;

  # To prevent circular dependency
  # as harlequin-odbc requires harlequin which requires harlequin-odbc
  pythonRemoveDeps = [
    "harlequin"
  ];

  meta = {
    description = "A Harlequin adapter for ODBC";
    homepage = "https://pypi.org/project/harlequin-odbc/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      pcboy
      {
        email = "git@bowmanjd.org";
        github = "bowmanjd";
        githubId = 86415;
        name = "Jonathan Bowman";
      }
    ];
  };
}
