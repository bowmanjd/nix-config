{ lib, stdenv, fetchFromGitHub, rustPlatform, Security }:

rustPlatform.buildRustPackage rec {
  pname = "qsv";
  version = "0.119.0";

  src = fetchFromGitHub {
    owner = "jqnatividad";
    repo = "qsv";
    rev = version;
    hash = "";
  };

  cargoSha256 = "";

  buildInputs = lib.optional stdenv.isDarwin Security;

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
