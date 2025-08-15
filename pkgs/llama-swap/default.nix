{
  lib,
  stdenv,
  nodejs,
  gnumake,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  # stdenv.mkDerivation {
  pname = "llama-swap";
  version = "151";

  src = fetchFromGitHub {
    owner = "mostlygeek";
    repo = "llama-swap";
    rev = "v${version}";
    hash = "sha256-f2cKSbNjaoM5nqF3hQbvXMxzZJ6et8poX6wZh9Bme7M=";
  };

  vendorHash = "sha256-5mmciFAGe8ZEIQvXejhYN+ocJL3wOVwevIieDuokhGU=";

  nativeBuildInputs = [nodejs gnumake];

  buildPhase = ''
    make clean all
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp build/llama-swap $out/bin/
  '';

  meta = with lib; {
    description = "Model swapping for llama.cpp";
    homepage = "https://github.com/mostlygeek/llama-swap";
    license = licenses.mit;
    maintainers = [
      {
        email = "git@bowmanjd.org";
        github = "bowmanjd";
        githubId = 86415;
        name = "Jonathan Bowman";
      }
    ];
  };
}
