{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
}: let
  version = "157";
  # srcHash = "sha256-0AA0DXB8MLVTPdFZ9J4H7h7TF7ZWnzQ/wf1ZfCo+Dag=";
  srcHash = "";

  react-ui = buildNpmPackage {
    pname = "llama-swap-ui";
    version = version;

    src = fetchFromGitHub {
      owner = "mostlygeek";
      repo = "llama-swap";
      rev = "v${version}";
      hash = srcHash;
    };

    sourceRoot = "source/ui";
    npmDepsHash = "";
    # npmDepsHash = "sha256-Sbvz3oudMVf+PxOJ6s7LsDaxFwvftNc8ZW5KPpbI/cA=";

    buildPhase = ''
      npm run build -- --outDir dist
    '';

    installPhase = ''
      cp -r dist $out
    '';
  };
in
  buildGoModule {
    pname = "llama-swap";
    version = version;
    src = fetchFromGitHub {
      owner = "mostlygeek";
      repo = "llama-swap";
      rev = "v${version}";
      hash = srcHash;
    };

    vendorHash = "sha256-5mmciFAGe8ZEIQvXejhYN+ocJL3wOVwevIieDuokhGU=";

    doCheck = false;

    buildPhase = ''
      mkdir -p proxy/ui_dist
      cp -r ${react-ui}/* proxy/ui_dist/
      go build -o llama-swap .
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp llama-swap $out/bin/
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
