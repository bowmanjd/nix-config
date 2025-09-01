{
  description = "Jonathan Bowman nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llama-cpp-overlay = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    rust-overlay,
    llama-cpp-overlay,
    nix-ai-tools,
    ...
  } @ inputs: let
    inherit (self) outputs;
    inherit (nixpkgs) lib;
    systems = ["x86_64-linux"];
    forAllSystems = lib.genAttrs systems;

    # Add stable nixpkgs as overlay
    overlay-stable = final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.system;
        config.allowUnfree = true;
      };
    };

    # Overlay to enable CPU optimizations for llama.cpp (current CMake flags)

    llama-cpp-optimized = final: prev: {
      llama-cpp = prev.llama-cpp.overrideAttrs (old: {
        # replace, don't append, to avoid contradictory defaults
        cmakeFlags = [
          "-GNinja"
          "-DCMAKE_BUILD_TYPE=Release"
          "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON" # LTO

          # ggml CPU flags (modern names)
          # SSE42 AVX F16C AVX2 BMI2 FMA AVX512 AVX512_VBMI AVX512_VNNI
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

          # threading; start with no BLAS (often best for decode)
          "-DGGML_OPENMP=ON"
          "-DGGML_BLAS=OFF"

          # optional quality-of-life
          "-DLLAMA_BUILD_SERVER=ON"
          "-DBUILD_SHARED_LIBS=ON"
        ];

        NIX_CFLAGS_COMPILE =
          (old.NIX_CFLAGS_COMPILE or "")
          + " -O3 -march=native -mtune=native";
      });
    };

    # Create a common function for NixOS configurations
    mkNixosSystem = {
      hostname,
      username,
      nixosConfigFile,
      homeConfigFile,
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules =
          [
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
                extraSpecialArgs = {inherit inputs outputs;};
              };
            }
          ]
          ++ extraModules;
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    overlays = import ./overlays {inherit inputs;};

    # NixOS configuration entrypoint
    nixosConfigurations = {
      # Available through 'sudo nixos-rebuild switch --flake .#lappy386'
      lappy386 = mkNixosSystem {
        hostname = "lappy386";
        username = "bowmanjd";
        nixosConfigFile = ./nixos/lappy.nix;
        homeConfigFile = ./home-manager/home.nix;
      };

      # Available through 'sudo nixos-rebuild switch --flake .#work'
      work = mkNixosSystem {
        hostname = "jbowman-cargas";
        username = "jbowman";
        nixosConfigFile = ./nixos/work.nix;
        homeConfigFile = ./home-manager/work.nix;
      };
    };
  };
}
