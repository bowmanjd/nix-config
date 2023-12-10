{ lib, stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "qsv";
  version = "0.119.0";

  src = fetchFromGitHub {
    owner = "jqnatividad";
    repo = "qsv";
    rev = version;
    hash = "sha256-AGPXkFnxhCahPAIem/q7xvxaiKp/ny8+pODZoBSC870=";
  };

  cargoHash = "sha256-eTH25kPQe+BoR6Sp5LbZzWikjgOD4dJ7SBTut9C4Kp4=";

  meta = with lib; {
    description = "CSVs sliced, diced & analyzed.";
    homepage = "https://github.com/jqnatividad/qsv";
    license = with licenses; [ unlicense /* or */ mit ];
    maintainers = [ {
      email = "git@bowmanjd.org";
      github = "bowmanjd";
      githubId = 86415;
      name = "Jonathan Bowman";
    } ];
  };
}
