{
  lib,
  stdenv,
  nodejs,
  gnumake,
  go,
  makeWrapper,
  llama-cpp,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
}: let
  react-ui = buildNpmPackage rec {
    pname = "llama-swap-ui";
    version = "151";

    src = fetchFromGitHub {
      owner = "mostlygeek";
      repo = "llama-swap";
      rev = "v${version}";
      hash = "sha256-f2cKSbNjaoM5nqF3hQbvXMxzZJ6et8poX6wZh9Bme7M=";
    };

    sourceRoot = "source/ui"; # We only care about the ui subdirectory

    npmDepsHash = "sha256-Sbvz3oudMVf+PxOJ6s7LsDaxFwvftNc8ZW5KPpbI/cA=";

    # Ensure Vite writes within sourceRoot (ui), not ../proxy
    buildPhase = ''
      runHook preBuild
      npm run build -- --outDir dist
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };
in
  buildGoModule rec {
    pname = "llama-swap";
    version = "151";

    src = fetchFromGitHub {
      owner = "mostlygeek";
      repo = "llama-swap";
      rev = "v${version}";
      hash = "sha256-f2cKSbNjaoM5nqF3hQbvXMxzZJ6et8poX6wZh9Bme7M=";
    };

    vendorHash = "sha256-5mmciFAGe8ZEIQvXejhYN+ocJL3wOVwevIieDuokhGU=";

    nativeBuildInputs = [ makeWrapper gnumake go nodejs ];
    doCheck = false;

    preBuild = ''
      mkdir -p proxy/ui_dist
      cp -r ${react-ui}/* proxy/ui_dist/
    '';

    buildPhase = ''
      runHook preBuild
      go build -o llama-swap .
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp llama-swap $out/bin/

      # Wrap the binary to make llama-cpp's binaries available in the PATH
      wrapProgram $out/bin/llama-swap \
        --prefix PATH : ${lib.makeBinPath [llama-cpp]}
      runHook postInstall
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
