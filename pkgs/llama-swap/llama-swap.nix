{ stdenv, lib, fetchFromGitHub, buildGoModule, buildNpmPackage, nodejs, gnumake, makeWrapper, llama-cpp, go }:

let
  # Stage 1: Build the React UI
  react-ui = buildNpmPackage {
    pname = "llama-swap-ui";
    version = "unstable";

    src = fetchFromGitHub {
      owner = "mostlygeek";
      repo = "llama-swap";
      rev = "main"; # or a specific tag/commit
      hash = lib.fakeHash; # placeholder for src hash
    };

    sourceRoot = "source/ui"; # We only care about the ui subdirectory

    npmDepsHash = lib.fakeHash; # placeholder for npmDepsHash

    # buildNpmPackage will automatically run 'npm install'
    # We just need to tell it what build command to run after.
    # This comes from the "build" script in ui/package.json
    buildPhase = ''
      runHook preBuild
      npm run build
      runHook postBuild
    '';

    # The result of 'npm run build' is a 'dist' directory.
    # We need to copy it to the output.
    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };

in
# Stage 2: Build the Go binary and wrap it
buildGoModule rec {
  pname = "llama-swap";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "mostlygeek";
    repo = "llama-swap";
    rev = "main"; # or a specific tag/commit
    hash = lib.fakeHash; # placeholder for src hash
  };

  vendorHash = lib.fakeHash; # placeholder for vendorHash

  nativeBuildInputs = [ makeWrapper gnumake go nodejs ];

  # Before building, copy the pre-built UI into the source tree
  preBuild = ''
    mkdir -p proxy/ui_dist
    cp -r ${react-ui}/* proxy/ui_dist/
  '';

  # We no longer use the Makefile, as it tries to run npm install.
  # Instead, we run the go build command directly.
  # The ldflags are removed for simplicity and reproducibility.
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
      --prefix PATH : ${lib.makeBinPath [ llama-cpp ]}
    runHook postInstall
  '';

  meta = with lib; {
    description = "A lightweight, transparent proxy server that provides automatic model swapping to llama.cpp's server.";
    homepage = "https://github.com/mostlygeek/llama-swap";
    license = licenses.mit; # Please verify this from LICENSE.md
    maintainers = with maintainers; [ ];
  };
}
