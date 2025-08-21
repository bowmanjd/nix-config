{
  description = "Jonathan Bowman nix config";

  inputs = {
    # Pin channels
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home Manager (follows nixpkgs)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tooling/overlays
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llama-cpp-overlay = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional extras (kept for future use)
    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, rust-overlay, llama-cpp-overlay, ... }: let
    inherit (nixpkgs) lib;

    systems = [ "x86_64-linux" ];
    forAllSystems = lib.genAttrs systems;

    # Stable nixpkgs overlay
    overlay-stable = final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.system;
        config.allowUnfree = true;
      };
    };

    # llama.cpp CPU-optimized build
    llama-cpp-optimized = final: prev: {
      llama-cpp = prev.llama-cpp.overrideAttrs (old: {
        cmakeFlags = [
          "-GNinja"
          "-DCMAKE_BUILD_TYPE=Release"
          "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON"
          "-DGGML_NATIVE=ON"
          "-DGGML_SSE42=ON"
          "-DGGML_AVX=ON"
          "-DGGML_F16C=ON"
          "-DGGML_AVX2=ON"
          "-DGGML_BMI2=ON"
          "-DGGML_FMA=ON"
          "-DGGML_AVX512=ON"
          "-DGGML_AVX512_VBMI=ON"
          "-DGGML_AVX512_VNNI=ON"
          "-DGGML_OPENMP=ON"
          "-DGGML_BLAS=OFF"
          "-DLLAMA_BUILD_SERVER=ON"
          "-DBUILD_SHARED_LIBS=ON"
        ];
        NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -O3 -march=native -mtune=native";
      });
    };

    # Helper to define NixOS systems
    mkNixosSystem = { hostname, username, nixosConfigFile, homeConfigFile, extraModules ? [] }:
      nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.overlays = [
              overlay-stable
              rust-overlay.overlays.default
              llama-cpp-overlay.overlays.default
              llama-cpp-optimized
            ];
            networking.hostName = hostname;
          }
          nixosConfigFile
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${username} = import homeConfigFile;
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ] ++ extraModules;
      };
  in {
    # Formatters and overlays
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import ./overlays { inherit inputs; };

    # Packages by system
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    # Hosts
    nixosConfigurations = {
      lappy386 = mkNixosSystem {
        hostname = "lappy386";
        username = "bowmanjd";
        nixosConfigFile = ./nixos/lappy.nix;
        homeConfigFile = ./home-manager/home.nix;
      };
      work = mkNixosSystem {
        hostname = "jbowman-cargas";
        username = "jbowman";
        nixosConfigFile = ./nixos/work.nix;
        homeConfigFile = ./home-manager/work.nix;
      };
    };
  };
}
