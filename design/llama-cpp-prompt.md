# Prompt for an Advanced LLM: Devising a NixOS Strategy

## 1. The Persona

You are an expert-level NixOS and Flakes engineer. You are a master at structuring complex Nix configurations in a clean, maintainable, and idiomatic way. You think step-by-step and always explain the reasoning behind your architectural decisions.

## 2. The Scenario & Goal

I have a NixOS configuration for a fleet of machines, all managed within a single git repository using a central `flake.nix`.

My goal is to **stop using the `llama-cpp` package from the standard `nixpkgs` and instead use the package directly from the official `llama.cpp` git repository** available at https://github.com/ggml-org/llama.cpp/, which is available as its own flake.

A **critical requirement** is that the build must be **optimized for the specific hardware of each machine**.
- Some machines have NVIDIA GPUs and should use a **CUDA-accelerated** build.
- Others might need a **Vulkan-accelerated** build.
- Others are cpu-only and have no supported GPU to speak of
- All, however, should use aggressive CPU architecture-specific optimizations (e.g., AVX, AVX512, FMA, etc.).

I value a clean, modular, and easy-to-understand configuration.

## 3. Key Information & File Contents

To devise your strategy, you must analyze the following files. I will provide their contents. Please explicitly reference them in your analysis.

**File A: My root `flake.nix`**
This is the main entry point for my entire system. Pay close attention to how `inputs`, `overlays`, and `specialArgs` are used for the `nixosConfigurations`.

```nix
{
  description = "techyporcupine's NixOS Config!";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Nixos-hardware
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    # Packages I just want the latest of
    waybar = {
      url = "github:Alexays/Waybar/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager config
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, ...} @ inputs: let
    inherit (self) outputs;
    overlay-stable = final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.system;
        config.allowUnfree = true;
      };
    };
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
    # NixOS configuration entrypoint
    # To switch to new NixOS config 'nh os switch ./' as long as the hostname of your device is the same as the nixosConfiguration name!
  in {
    nixosConfigurations = {
      carbon = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        # Path to NixOS configuration
        modules = [
          ({
            config,
            pkgs,
            ...
          }: {
            nixpkgs.overlays = [
              overlay-stable
            ];
          })
          ./machines/carbon.nix
          ./nixos
          inputs.home-manager.nixosModules.home-manager
          inputs.nixos-hardware.nixosModules.framework-13-7040-amd
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs outputs;};
          }
        ];
      };
      beryllium = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        # Path to NixOS configuration
        modules = [
          ({
            config,
            pkgs,
            ...
          }: {
            nixpkgs.overlays = [
              overlay-stable
            ];
          })
          ./machines/beryllium.nix
          ./nixos
          inputs.home-manager.nixosModules.home-manager
          inputs.nixos-hardware.nixosModules.framework-13-7040-amd
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs outputs;};
          }
        ];
      };
      boron = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        # Path to NixOS configuration
        modules = [
          ({
            config,
            pkgs,
            ...
          }: {
            nixpkgs.overlays = [
              overlay-stable
            ];
          })
          ./machines/boron.nix
          ./nixos
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs outputs;};
          }
        ];
      };
      nitrogen = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        # Path to NixOS configuration
        modules = [
          ({
            config,
            pkgs,
            ...
          }: {
            nixpkgs.overlays = [
              overlay-stable
            ];
          })
          ./machines/nitrogen.nix
          ./nixos
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs outputs;};
          }
        ];
      };
    };
  };
}
```

---

**File B: The `llama.cpp` Flake Source Code**
The official repository is located at `github:ggml-org/llama.cpp`. To understand how to use it, you must analyze its Nix build logic. The key files are:
1.  `llama.cpp/flake.nix` (The main flake entrypoint)

```nix
# The flake interface to llama.cpp's Nix expressions. The flake is used as a
# more discoverable entry-point, as well as a way to pin the dependencies and
# expose default outputs, including the outputs built by the CI.

# For more serious applications involving some kind of customization  you may
# want to consider consuming the overlay, or instantiating `llamaPackages`
# directly:
#
# ```nix
# pkgs.callPackage ${llama-cpp-root}/.devops/nix/scope.nix { }`
# ```

# Cf. https://jade.fyi/blog/flakes-arent-real/ for a more detailed exposition
# of the relation between Nix and the Nix Flakes.
{
  description = "Port of Facebook's LLaMA model in C/C++";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  # There's an optional binary cache available. The details are below, but they're commented out.
  #
  # Why? The terrible experience of being prompted to accept them on every single Nix command run.
  # Plus, there are warnings shown about not being a trusted user on a default Nix install
  # if you *do* say yes to the prompts.
  #
  # This experience makes having `nixConfig` in a flake a persistent UX problem.
  #
  # To make use of the binary cache, please add the relevant settings to your `nix.conf`.
  # It's located at `/etc/nix/nix.conf` on non-NixOS systems. On NixOS, adjust the `nix.settings`
  # option in your NixOS configuration to add `extra-substituters` and `extra-trusted-public-keys`,
  # as shown below.
  #
  # ```
  # nixConfig = {
  #   extra-substituters = [
  #     # A development cache for nixpkgs imported with `config.cudaSupport = true`.
  #     # Populated by https://hercules-ci.com/github/SomeoneSerge/nixpkgs-cuda-ci.
  #     # This lets one skip building e.g. the CUDA-enabled openmpi.
  #     # TODO: Replace once nix-community obtains an official one.
  #     "https://cuda-maintainers.cachix.org"
  #   ];
  #
  #   # Verify these are the same keys as published on
  #   # - https://app.cachix.org/cache/cuda-maintainers
  #   extra-trusted-public-keys = [
  #     "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
  #   ];
  # };
  # ```

  # For inspection, use `nix flake show github:ggml-org/llama.cpp` or the nix repl:
  #
  # ```bash
  # ❯ nix repl
  # nix-repl> :lf github:ggml-org/llama.cpp
  # Added 13 variables.
  # nix-repl> outputs.apps.x86_64-linux.quantize
  # { program = "/nix/store/00000000000000000000000000000000-llama.cpp/bin/llama-quantize"; type = "app"; }
  # ```
  outputs =
    { self, flake-parts, ... }@inputs:
    let
      # We could include the git revisions in the package names but those would
      # needlessly trigger rebuilds:
      # llamaVersion = self.dirtyShortRev or self.shortRev;

      # Nix already uses cryptographic hashes for versioning, so we'll just fix
      # the fake semver for now:
      llamaVersion = "0.0.0";
    in
    flake-parts.lib.mkFlake { inherit inputs; }

      {

        imports = [
          .devops/nix/nixpkgs-instances.nix
          .devops/nix/apps.nix
          .devops/nix/devshells.nix
          .devops/nix/jetson-support.nix
        ];

        # An overlay can be used to have a more granular control over llama-cpp's
        # dependencies and configuration, than that offered by the `.override`
        # mechanism. Cf. https://nixos.org/manual/nixpkgs/stable/#chap-overlays.
        #
        # E.g. in a flake:
        # ```
        # { nixpkgs, llama-cpp, ... }:
        # let pkgs = import nixpkgs {
        #     overlays = [ (llama-cpp.overlays.default) ];
        #     system = "aarch64-linux";
        #     config.allowUnfree = true;
        #     config.cudaSupport = true;
        #     config.cudaCapabilities = [ "7.2" ];
        #     config.cudaEnableForwardCompat = false;
        # }; in {
        #     packages.aarch64-linux.llamaJetsonXavier = pkgs.llamaPackages.llama-cpp;
        # }
        # ```
        #
        # Cf. https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html?highlight=flake#flake-format
        flake.overlays.default = (
          final: prev: {
            llamaPackages = final.callPackage .devops/nix/scope.nix { inherit llamaVersion; };
            inherit (final.llamaPackages) llama-cpp;
          }
        );

        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin" # x86_64-darwin isn't tested (and likely isn't relevant)
          "x86_64-linux"
        ];

        perSystem =
          {
            config,
            lib,
            system,
            pkgs,
            pkgsCuda,
            pkgsRocm,
            ...
          }:
          {
            # For standardised reproducible formatting with `nix fmt`
            formatter = pkgs.nixfmt-rfc-style;

            # Unlike `.#packages`, legacyPackages may contain values of
            # arbitrary types (including nested attrsets) and may even throw
            # exceptions. This attribute isn't recursed into by `nix flake
            # show` either.
            #
            # You can add arbitrary scripts to `.devops/nix/scope.nix` and
            # access them as `nix build .#llamaPackages.${scriptName}` using
            # the same path you would with an overlay.
            legacyPackages = {
              llamaPackages = pkgs.callPackage .devops/nix/scope.nix { inherit llamaVersion; };
              llamaPackagesWindows = pkgs.pkgsCross.mingwW64.callPackage .devops/nix/scope.nix {
                inherit llamaVersion;
              };
              llamaPackagesCuda = pkgsCuda.callPackage .devops/nix/scope.nix { inherit llamaVersion; };
              llamaPackagesRocm = pkgsRocm.callPackage .devops/nix/scope.nix { inherit llamaVersion; };
            };

            # We don't use the overlay here so as to avoid making too many instances of nixpkgs,
            # cf. https://zimbatm.com/notes/1000-instances-of-nixpkgs
            packages =
              {
                default = config.legacyPackages.llamaPackages.llama-cpp;
                vulkan = config.packages.default.override { useVulkan = true; };
                windows = config.legacyPackages.llamaPackagesWindows.llama-cpp;
                python-scripts = config.legacyPackages.llamaPackages.python-scripts;
              }
              // lib.optionalAttrs pkgs.stdenv.isLinux {
                cuda = config.legacyPackages.llamaPackagesCuda.llama-cpp;

                mpi-cpu = config.packages.default.override { useMpi = true; };
                mpi-cuda = config.packages.default.override { useMpi = true; };
              }
              // lib.optionalAttrs (system == "x86_64-linux") {
                rocm = config.legacyPackages.llamaPackagesRocm.llama-cpp;
              };

            # Packages exposed in `.#checks` will be built by the CI and by
            # `nix flake check`.
            #
            # We could test all outputs e.g. as `checks = confg.packages`.
            #
            # TODO: Build more once https://github.com/ggml-org/llama.cpp/issues/6346 has been addressed
            checks = {
              inherit (config.packages) default vulkan;
            };
          };
      };
}
```

2.  `llama.cpp/.devops/nix/scope.nix` (The package set definition)

```nix
{
  lib,
  newScope,
  python3,
  llamaVersion ? "0.0.0",
}:

let
  pythonPackages = python3.pkgs;
  buildPythonPackage = pythonPackages.buildPythonPackage;
  numpy = pythonPackages.numpy;
  tqdm = pythonPackages.tqdm;
  sentencepiece = pythonPackages.sentencepiece;
  pyyaml = pythonPackages.pyyaml;
  poetry-core = pythonPackages.poetry-core;
  pytestCheckHook = pythonPackages.pytestCheckHook;
in

# We're using `makeScope` instead of just writing out an attrset
# because it allows users to apply overlays later using `overrideScope'`.
# Cf. https://noogle.dev/f/lib/makeScope

lib.makeScope newScope (self: {
  inherit llamaVersion;
  gguf-py = self.callPackage ./package-gguf-py.nix {
    inherit
      buildPythonPackage
      numpy
      tqdm
      sentencepiece
      poetry-core
      pyyaml
      pytestCheckHook
      ;
  };
  python-scripts = self.callPackage ./python-scripts.nix { inherit buildPythonPackage poetry-core; };
  llama-cpp = self.callPackage ./package.nix { };
  docker = self.callPackage ./docker.nix { };
  docker-min = self.callPackage ./docker.nix { interactive = false; };
  sif = self.callPackage ./sif.nix { };
})
```

3.  `llama.cpp/.devops/nix/package.nix` (The core package derivation with all build options)

```nix
{
  lib,
  glibc,
  config,
  stdenv,
  runCommand,
  cmake,
  ninja,
  pkg-config,
  git,
  mpi,
  blas,
  cudaPackages,
  autoAddDriverRunpath,
  darwin,
  rocmPackages,
  vulkan-headers,
  vulkan-loader,
  curl,
  shaderc,
  useBlas ?
    builtins.all (x: !x) [
      useCuda
      useMetalKit
      useRocm
      useVulkan
    ]
    && blas.meta.available,
  useCuda ? config.cudaSupport,
  useMetalKit ? stdenv.isAarch64 && stdenv.isDarwin,
  # Increases the runtime closure size by ~700M
  useMpi ? false,
  useRocm ? config.rocmSupport,
  rocmGpuTargets ? builtins.concatStringsSep ";" rocmPackages.clr.gpuTargets,
  enableCurl ? true,
  useVulkan ? false,
  llamaVersion ? "0.0.0", # Arbitrary version, substituted by the flake

  # It's necessary to consistently use backendStdenv when building with CUDA support,
  # otherwise we get libstdc++ errors downstream.
  effectiveStdenv ? if useCuda then cudaPackages.backendStdenv else stdenv,
  enableStatic ? effectiveStdenv.hostPlatform.isStatic,
  precompileMetalShaders ? false,
}:

let
  inherit (lib)
    cmakeBool
    cmakeFeature
    optionalAttrs
    optionals
    strings
    ;

  stdenv = throw "Use effectiveStdenv instead";

  suffices =
    lib.optionals useBlas [ "BLAS" ]
    ++ lib.optionals useCuda [ "CUDA" ]
    ++ lib.optionals useMetalKit [ "MetalKit" ]
    ++ lib.optionals useMpi [ "MPI" ]
    ++ lib.optionals useRocm [ "ROCm" ]
    ++ lib.optionals useVulkan [ "Vulkan" ];

  pnameSuffix =
    strings.optionalString (suffices != [ ])
      "-${strings.concatMapStringsSep "-" strings.toLower suffices}";
  descriptionSuffix = strings.optionalString (
    suffices != [ ]
  ) ", accelerated with ${strings.concatStringsSep ", " suffices}";

  xcrunHost = runCommand "xcrunHost" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/xcrun $out/bin
  '';

  # apple_sdk is supposed to choose sane defaults, no need to handle isAarch64
  # separately
  darwinBuildInputs =
    with darwin.apple_sdk.frameworks;
    [
      Accelerate
      CoreVideo
      CoreGraphics
    ]
    ++ optionals useMetalKit [ MetalKit ];

  cudaBuildInputs = with cudaPackages; [
    cuda_cudart
    cuda_cccl # <nv/target>
    libcublas
  ];

  rocmBuildInputs = with rocmPackages; [
    clr
    hipblas
    rocblas
  ];

  vulkanBuildInputs = [
    vulkan-headers
    vulkan-loader
    shaderc
  ];
in

effectiveStdenv.mkDerivation (finalAttrs: {
  pname = "llama-cpp${pnameSuffix}";
  version = llamaVersion;

  # Note: none of the files discarded here are visible in the sandbox or
  # affect the output hash. This also means they can be modified without
  # triggering a rebuild.
  src = lib.cleanSourceWith {
    filter =
      name: type:
      let
        noneOf = builtins.all (x: !x);
        baseName = baseNameOf name;
      in
      noneOf [
        (lib.hasSuffix ".nix" name) # Ignore *.nix files when computing outPaths
        (lib.hasSuffix ".md" name) # Ignore *.md changes whe computing outPaths
        (lib.hasPrefix "." baseName) # Skip hidden files and directories
        (baseName == "flake.lock")
      ];
    src = lib.cleanSource ../../.;
  };

  postPatch = ''
    substituteInPlace ./ggml/src/ggml-metal/ggml-metal.m \
      --replace '[bundle pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/bin/ggml-metal.metal\";"
    substituteInPlace ./ggml/src/ggml-metal/ggml-metal.m \
      --replace '[bundle pathForResource:@"default" ofType:@"metallib"];' "@\"$out/bin/default.metallib\";"
  '';

  # With PR#6015 https://github.com/ggml-org/llama.cpp/pull/6015,
  # `default.metallib` may be compiled with Metal compiler from XCode
  # and we need to escape sandbox on MacOS to access Metal compiler.
  # `xcrun` is used find the path of the Metal compiler, which is varible
  # and not on $PATH
  # see https://github.com/ggml-org/llama.cpp/pull/6118 for discussion
  __noChroot = effectiveStdenv.isDarwin && useMetalKit && precompileMetalShaders;

  nativeBuildInputs =
    [
      cmake
      ninja
      pkg-config
      git
    ]
    ++ optionals useCuda [
      cudaPackages.cuda_nvcc

      autoAddDriverRunpath
    ]
    ++ optionals (effectiveStdenv.hostPlatform.isGnu && enableStatic) [ glibc.static ]
    ++ optionals (effectiveStdenv.isDarwin && useMetalKit && precompileMetalShaders) [ xcrunHost ];

  buildInputs =
    optionals effectiveStdenv.isDarwin darwinBuildInputs
    ++ optionals useCuda cudaBuildInputs
    ++ optionals useMpi [ mpi ]
    ++ optionals useRocm rocmBuildInputs
    ++ optionals useBlas [ blas ]
    ++ optionals useVulkan vulkanBuildInputs
    ++ optionals enableCurl [ curl ];

  cmakeFlags =
    [
      (cmakeBool "LLAMA_BUILD_SERVER" true)
      (cmakeBool "BUILD_SHARED_LIBS" (!enableStatic))
      (cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
      (cmakeBool "LLAMA_CURL" enableCurl)
      (cmakeBool "GGML_NATIVE" false)
      (cmakeBool "GGML_BLAS" useBlas)
      (cmakeBool "GGML_CUDA" useCuda)
      (cmakeBool "GGML_HIP" useRocm)
      (cmakeBool "GGML_METAL" useMetalKit)
      (cmakeBool "GGML_VULKAN" useVulkan)
      (cmakeBool "GGML_STATIC" enableStatic)
    ]
    ++ optionals useCuda [
      (
        with cudaPackages.flags;
        cmakeFeature "CMAKE_CUDA_ARCHITECTURES" (
          builtins.concatStringsSep ";" (map dropDot cudaCapabilities)
        )
      )
    ]
    ++ optionals useRocm [
      (cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.llvm.clang}/bin/clang")
      (cmakeFeature "CMAKE_HIP_ARCHITECTURES" rocmGpuTargets)
    ]
    ++ optionals useMetalKit [
      (lib.cmakeFeature "CMAKE_C_FLAGS" "-D__ARM_FEATURE_DOTPROD=1")
      (cmakeBool "GGML_METAL_EMBED_LIBRARY" (!precompileMetalShaders))
    ];

  # Environment variables needed for ROCm
  env = optionalAttrs useRocm {
    ROCM_PATH = "${rocmPackages.clr}";
    HIP_DEVICE_LIB_PATH = "${rocmPackages.rocm-device-libs}/amdgcn/bitcode";
  };

  # TODO(SomeoneSerge): It's better to add proper install targets at the CMake level,
  # if they haven't been added yet.
  postInstall = ''
    mkdir -p $out/include
    cp $src/include/llama.h $out/include/
  '';

  meta = {
    # Configurations we don't want even the CI to evaluate. Results in the
    # "unsupported platform" messages. This is mostly a no-op, because
    # cudaPackages would've refused to evaluate anyway.
    badPlatforms = optionals useCuda lib.platforms.darwin;

    # Configurations that are known to result in build failures. Can be
    # overridden by importing Nixpkgs with `allowBroken = true`.
    broken = (useMetalKit && !effectiveStdenv.isDarwin);

    description = "Inference of LLaMA model in pure C/C++${descriptionSuffix}";
    homepage = "https://github.com/ggml-org/llama.cpp/";
    license = lib.licenses.mit;

    # Accommodates `nix run` and `lib.getExe`
    mainProgram = "llama-cli";

    # These people might respond, on the best effort basis, if you ping them
    # in case of Nix-specific regressions or for reviewing Nix-specific PRs.
    # Consider adding yourself to this list if you want to ensure this flake
    # stays maintained and you're willing to invest your time. Do not add
    # other people without their consent. Consider removing people after
    # they've been unreachable for long periods of time.

    # Note that lib.maintainers is defined in Nixpkgs, but you may just add
    # an attrset following the same format as in
    # https://github.com/NixOS/nixpkgs/blob/f36a80e54da29775c78d7eff0e628c2b4e34d1d7/maintainers/maintainer-list.nix
    maintainers = with lib.maintainers; [
      philiptaron
      SomeoneSerge
    ];

    # Extend `badPlatforms` instead
    platforms = lib.platforms.all;
  };
})
```

4. **`.devops/nix/nixpkgs-instances.nix`**: This file is crucial for backend support. It creates specialized instances of `nixpkgs` for CUDA (`pkgsCuda`) and ROCm (`pkgsRocm`). These instances have the necessary `cudaSupport` and `rocmSupport` flags enabled, and they also handle the licensing for unfree software like the CUDA toolkit.

```nix
{ inputs, ... }:
{
  # The _module.args definitions are passed on to modules as arguments. E.g.
  # the module `{ pkgs ... }: { /* config */ }` implicitly uses
  # `_module.args.pkgs` (defined in this case by flake-parts).
  perSystem =
    { system, ... }:
    {
      _module.args = {
        # Note: bringing up https://zimbatm.com/notes/1000-instances-of-nixpkgs
        # again, the below creates several nixpkgs instances which the
        # flake-centric CLI will be forced to evaluate e.g. on `nix flake show`.
        #
        # This is currently "slow" and "expensive", on a certain scale.
        # This also isn't "right" in that this hinders dependency injection at
        # the level of flake inputs. This might get removed in the foreseeable
        # future.
        #
        # Note that you can use these expressions without Nix
        # (`pkgs.callPackage ./devops/nix/scope.nix { }` is the entry point).

        pkgsCuda = import inputs.nixpkgs {
          inherit system;
          # Ensure dependencies use CUDA consistently (e.g. that openmpi, ucc,
          # and ucx are built with CUDA support)
          config.cudaSupport = true;
          config.allowUnfreePredicate =
            p:
            builtins.all (
              license:
              license.free
              || builtins.elem license.shortName [
                "CUDA EULA"
                "cuDNN EULA"
              ]
            ) (p.meta.licenses or [ p.meta.license ]);
        };
        # Ensure dependencies use ROCm consistently
        pkgsRocm = import inputs.nixpkgs {
          inherit system;
          config.rocmSupport = true;
        };
      };
    };
}
```

5. **`CMakeLists.txt`**: The CMake file reveals the build options that can be toggled. The Nix derivation in `.devops/nix/package.nix` manipulates these CMake options (e.g., `GGML_CUDA`, `GGML_HIP`, `GGML_VULKAN`). For CPU optimizations, it appears the build system can detect and apply them, but the Nix expressions set `GGML_NATIVE` to `false`, relying on Nixpkgs for optimizations. For fine-grained control, we may need to inject compiler flags.

```cmake
cmake_minimum_required(VERSION 3.14) # for add_link_options and implicit target directories.
project("ggml" C CXX ASM)
include(CheckIncludeFileCXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if (NOT XCODE AND NOT MSVC AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(GGML_STANDALONE ON)

    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

    # configure project version
    # TODO
else()
    set(GGML_STANDALONE OFF)
endif()

if (EMSCRIPTEN)
    set(BUILD_SHARED_LIBS_DEFAULT OFF)

    option(GGML_WASM_SINGLE_FILE "ggml: embed WASM inside the generated ggml.js" ON)
else()
    if (MINGW)
        set(BUILD_SHARED_LIBS_DEFAULT OFF)
    else()
        set(BUILD_SHARED_LIBS_DEFAULT ON)
    endif()
endif()

# remove the lib prefix on win32 mingw
if (WIN32)
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_MODULE_PREFIX  "")
endif()

option(BUILD_SHARED_LIBS           "ggml: build shared libraries" ${BUILD_SHARED_LIBS_DEFAULT})
option(GGML_BACKEND_DL             "ggml: build backends as dynamic libraries (requires BUILD_SHARED_LIBS)" OFF)
set(GGML_BACKEND_DIR "" CACHE PATH "ggml: directory to load dynamic backends from (requires GGML_BACKEND_DL")

#
# option list
#

# TODO: mark all options as advanced when not GGML_STANDALONE

if (APPLE)
    set(GGML_METAL_DEFAULT ON)
    set(GGML_BLAS_DEFAULT ON)
    set(GGML_BLAS_VENDOR_DEFAULT "Apple")
else()
    set(GGML_METAL_DEFAULT OFF)
    set(GGML_BLAS_DEFAULT OFF)
    set(GGML_BLAS_VENDOR_DEFAULT "Generic")
endif()

if (CMAKE_CROSSCOMPILING OR DEFINED ENV{SOURCE_DATE_EPOCH})
    message(STATUS "Setting GGML_NATIVE_DEFAULT to OFF")
    set(GGML_NATIVE_DEFAULT OFF)
else()
    set(GGML_NATIVE_DEFAULT ON)
endif()

# defaults
if (NOT GGML_LLAMAFILE_DEFAULT)
    set(GGML_LLAMAFILE_DEFAULT OFF)
endif()

if (NOT GGML_CUDA_GRAPHS_DEFAULT)
    set(GGML_CUDA_GRAPHS_DEFAULT OFF)
endif()

# general
option(GGML_STATIC "ggml: static link libraries"                     OFF)
option(GGML_NATIVE "ggml: optimize the build for the current system" ${GGML_NATIVE_DEFAULT})
option(GGML_LTO    "ggml: enable link time optimization"             OFF)
option(GGML_CCACHE "ggml: use ccache if available"                   ON)

# debug
option(GGML_ALL_WARNINGS           "ggml: enable all compiler warnings"                   ON)
option(GGML_ALL_WARNINGS_3RD_PARTY "ggml: enable all compiler warnings in 3rd party libs" OFF)
option(GGML_GPROF                  "ggml: enable gprof"                                   OFF)

# build
option(GGML_FATAL_WARNINGS    "ggml: enable -Werror flag"    OFF)

# sanitizers
option(GGML_SANITIZE_THREAD    "ggml: enable thread sanitizer"    OFF)
option(GGML_SANITIZE_ADDRESS   "ggml: enable address sanitizer"   OFF)
option(GGML_SANITIZE_UNDEFINED "ggml: enable undefined sanitizer" OFF)

# instruction set specific
if (GGML_NATIVE OR NOT GGML_NATIVE_DEFAULT)
    set(INS_ENB OFF)
else()
    set(INS_ENB ON)
endif()

message(DEBUG "GGML_NATIVE         : ${GGML_NATIVE}")
message(DEBUG "GGML_NATIVE_DEFAULT : ${GGML_NATIVE_DEFAULT}")
message(DEBUG "INS_ENB             : ${INS_ENB}")

option(GGML_CPU_HBM          "ggml: use memkind for CPU HBM" OFF)
option(GGML_CPU_REPACK       "ggml: use runtime weight conversion of Q4_0 to Q4_X_X" ON)
option(GGML_CPU_KLEIDIAI     "ggml: use KleidiAI optimized kernels if applicable" OFF)
option(GGML_SSE42            "ggml: enable SSE 4.2"          ${INS_ENB})
option(GGML_AVX              "ggml: enable AVX"              ${INS_ENB})
option(GGML_AVX_VNNI         "ggml: enable AVX-VNNI"         OFF)
option(GGML_AVX2             "ggml: enable AVX2"             ${INS_ENB})
option(GGML_BMI2             "ggml: enable BMI2"             ${INS_ENB})
option(GGML_AVX512           "ggml: enable AVX512F"          OFF)
option(GGML_AVX512_VBMI      "ggml: enable AVX512-VBMI"      OFF)
option(GGML_AVX512_VNNI      "ggml: enable AVX512-VNNI"      OFF)
option(GGML_AVX512_BF16      "ggml: enable AVX512-BF16"      OFF)
if (NOT MSVC)
    # in MSVC F16C and FMA is implied with AVX2/AVX512
    option(GGML_FMA          "ggml: enable FMA"              ${INS_ENB})
    option(GGML_F16C         "ggml: enable F16C"             ${INS_ENB})
    # MSVC does not seem to support AMX
    option(GGML_AMX_TILE     "ggml: enable AMX-TILE"         OFF)
    option(GGML_AMX_INT8     "ggml: enable AMX-INT8"         OFF)
    option(GGML_AMX_BF16     "ggml: enable AMX-BF16"         OFF)
endif()
option(GGML_LASX             "ggml: enable lasx"             ON)
option(GGML_LSX              "ggml: enable lsx"              ON)
option(GGML_RVV              "ggml: enable rvv"              ON)
option(GGML_RV_ZFH           "ggml: enable riscv zfh"        ON)
option(GGML_RV_ZVFH          "ggml: enable riscv zvfh"       ON)
option(GGML_RV_ZICBOP        "ggml: enable riscv zicbop"     ON)
option(GGML_XTHEADVECTOR     "ggml: enable xtheadvector"     OFF)
option(GGML_VXE              "ggml: enable vxe"              ON)

option(GGML_CPU_ALL_VARIANTS "ggml: build all variants of the CPU backend (requires GGML_BACKEND_DL)" OFF)
set(GGML_CPU_ARM_ARCH        "" CACHE STRING "ggml: CPU architecture for ARM")
set(GGML_CPU_POWERPC_CPUTYPE "" CACHE STRING "ggml: CPU type for PowerPC")


if (MINGW)
    set(GGML_WIN_VER "0x602" CACHE STRING   "ggml: Windows version")
endif()

# ggml core
set(GGML_SCHED_MAX_COPIES  "4" CACHE STRING "ggml: max input copies for pipeline parallelism")
option(GGML_CPU                             "ggml: enable CPU backend"                        ON)

# 3rd party libs / backends
option(GGML_ACCELERATE                      "ggml: enable Accelerate framework"               ON)
option(GGML_BLAS                            "ggml: use BLAS"                                  ${GGML_BLAS_DEFAULT})
set(GGML_BLAS_VENDOR ${GGML_BLAS_VENDOR_DEFAULT} CACHE STRING
                                            "ggml: BLAS library vendor")
option(GGML_LLAMAFILE                       "ggml: use LLAMAFILE"                             ${GGML_LLAMAFILE_DEFAULT})

option(GGML_CUDA                            "ggml: use CUDA"                                  OFF)
option(GGML_MUSA                            "ggml: use MUSA"                                  OFF)
option(GGML_CUDA_FORCE_MMQ                  "ggml: use mmq kernels instead of cuBLAS"         OFF)
option(GGML_CUDA_FORCE_CUBLAS               "ggml: always use cuBLAS instead of mmq kernels"  OFF)
set   (GGML_CUDA_PEER_MAX_BATCH_SIZE "128" CACHE STRING
                                            "ggml: max. batch size for using peer access")
option(GGML_CUDA_NO_PEER_COPY               "ggml: do not use peer to peer copies"            OFF)
option(GGML_CUDA_NO_VMM                     "ggml: do not try to use CUDA VMM"                OFF)
option(GGML_CUDA_FA                         "ggml: compile ggml FlashAttention CUDA kernels"  ON)
option(GGML_CUDA_FA_ALL_QUANTS              "ggml: compile all quants for FlashAttention"     OFF)
option(GGML_CUDA_GRAPHS                     "ggml: use CUDA graphs (llama.cpp only)"          ${GGML_CUDA_GRAPHS_DEFAULT})
set   (GGML_CUDA_COMPRESSION_MODE "size" CACHE STRING
                                            "ggml: cuda link binary compression mode; requires cuda 12.8+")
set_property(CACHE GGML_CUDA_COMPRESSION_MODE PROPERTY STRINGS "none;speed;balance;size")

option(GGML_HIP                             "ggml: use HIP"                                   OFF)
option(GGML_HIP_GRAPHS                      "ggml: use HIP graph, experimental, slow"         OFF)
option(GGML_HIP_NO_VMM                      "ggml: do not try to use HIP VMM"                 ON)
option(GGML_HIP_ROCWMMA_FATTN               "ggml: enable rocWMMA for FlashAttention"         OFF)
option(GGML_HIP_FORCE_ROCWMMA_FATTN_GFX12   "ggml: enable rocWMMA FlashAttention on GFX12"    OFF)
option(GGML_HIP_MMQ_MFMA                    "ggml: enable MFMA MMA for CDNA in MMQ"           ON)
option(GGML_HIP_EXPORT_METRICS              "ggml: enable kernel perf metrics output"         OFF)
option(GGML_MUSA_GRAPHS                     "ggml: use MUSA graph, experimental, unstable"    OFF)
option(GGML_MUSA_MUDNN_COPY                 "ggml: enable muDNN for accelerated copy"         OFF)
option(GGML_VULKAN                          "ggml: use Vulkan"                                OFF)
option(GGML_VULKAN_CHECK_RESULTS            "ggml: run Vulkan op checks"                      OFF)
option(GGML_VULKAN_DEBUG                    "ggml: enable Vulkan debug output"                OFF)
option(GGML_VULKAN_MEMORY_DEBUG             "ggml: enable Vulkan memory debug output"         OFF)
option(GGML_VULKAN_SHADER_DEBUG_INFO        "ggml: enable Vulkan shader debug info"           OFF)
option(GGML_VULKAN_VALIDATE                 "ggml: enable Vulkan validation"                  OFF)
option(GGML_VULKAN_RUN_TESTS                "ggml: run Vulkan tests"                          OFF)
option(GGML_WEBGPU                          "ggml: use WebGPU"                                OFF)
option(GGML_WEBGPU_DEBUG                    "ggml: enable WebGPU debug output"                OFF)
option(GGML_ZDNN                            "ggml: use zDNN"                                  OFF)
option(GGML_METAL                           "ggml: use Metal"                                 ${GGML_METAL_DEFAULT})
option(GGML_METAL_USE_BF16                  "ggml: use bfloat if available"                   OFF)
option(GGML_METAL_NDEBUG                    "ggml: disable Metal debugging"                   OFF)
option(GGML_METAL_SHADER_DEBUG              "ggml: compile Metal with -fno-fast-math"         OFF)
option(GGML_METAL_EMBED_LIBRARY             "ggml: embed Metal library"                       ${GGML_METAL})
set   (GGML_METAL_MACOSX_VERSION_MIN "" CACHE STRING
                                            "ggml: metal minimum macOS version")
set   (GGML_METAL_STD "" CACHE STRING       "ggml: metal standard version (-std flag)")
option(GGML_OPENMP                          "ggml: use OpenMP"                                ON)
option(GGML_RPC                             "ggml: use RPC"                                   OFF)
option(GGML_SYCL                            "ggml: use SYCL"                                  OFF)
option(GGML_SYCL_F16                        "ggml: use 16 bit floats for sycl calculations"   OFF)
option(GGML_SYCL_GRAPH                      "ggml: enable graphs in the SYCL backend"         ON)
option(GGML_SYCL_DNN                        "ggml: enable oneDNN in the SYCL backend"         ON)
set   (GGML_SYCL_TARGET "INTEL" CACHE STRING
                                            "ggml: sycl target device")
set   (GGML_SYCL_DEVICE_ARCH "" CACHE STRING
                                            "ggml: sycl device architecture")

option(GGML_OPENCL                          "ggml: use OpenCL"                                OFF)
option(GGML_OPENCL_PROFILING                "ggml: use OpenCL profiling (increases overhead)" OFF)
option(GGML_OPENCL_EMBED_KERNELS            "ggml: embed kernels"                             ON)
option(GGML_OPENCL_USE_ADRENO_KERNELS       "ggml: use optimized kernels for Adreno"          ON)
set   (GGML_OPENCL_TARGET_VERSION "300" CACHE STRING
                                            "gmml: OpenCL API version to target")

# toolchain for vulkan-shaders-gen
set   (GGML_VULKAN_SHADERS_GEN_TOOLCHAIN "" CACHE FILEPATH "ggml: toolchain file for vulkan-shaders-gen")

# extra artifacts
option(GGML_BUILD_TESTS    "ggml: build tests"    ${GGML_STANDALONE})
option(GGML_BUILD_EXAMPLES "ggml: build examples" ${GGML_STANDALONE})

#
# dependencies
#

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED true)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED true)

set(THREADS_PREFER_PTHREAD_FLAG ON)

find_package(Threads REQUIRED)

include(GNUInstallDirs)

#
# build the library
#

add_subdirectory(src)

#
# tests and examples
#

if (GGML_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif ()

if (GGML_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif ()

#
# install
#

include(CMakePackageConfigHelpers)

# all public headers
set(GGML_PUBLIC_HEADERS
    include/ggml.h
    include/ggml-cpu.h
    include/ggml-alloc.h
    include/ggml-backend.h
    include/ggml-blas.h
    include/ggml-cann.h
    include/ggml-cpp.h
    include/ggml-cuda.h
    include/ggml-opt.h
    include/ggml-metal.h
    include/ggml-rpc.h
    include/ggml-sycl.h
    include/ggml-vulkan.h
    include/ggml-webgpu.h
    include/gguf.h)

set_target_properties(ggml PROPERTIES PUBLIC_HEADER "${GGML_PUBLIC_HEADERS}")
#if (GGML_METAL)
#    set_target_properties(ggml PROPERTIES RESOURCE "${CMAKE_CURRENT_SOURCE_DIR}/src/ggml-metal.metal")
#endif()
install(TARGETS ggml LIBRARY PUBLIC_HEADER)
install(TARGETS ggml-base LIBRARY)

if (GGML_STANDALONE)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/ggml.pc.in
        ${CMAKE_CURRENT_BINARY_DIR}/ggml.pc
        @ONLY)

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/ggml.pc
        DESTINATION share/pkgconfig)
endif()

#
# Create CMake package
#

# Generate version info based on git commit.

if(NOT DEFINED GGML_BUILD_NUMBER)
    find_program(GIT_EXE NAMES git git.exe REQUIRED NO_CMAKE_FIND_ROOT_PATH)
    execute_process(COMMAND ${GIT_EXE} rev-list --count HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GGML_BUILD_NUMBER
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(GGML_BUILD_NUMBER EQUAL 1)
        message(WARNING "GGML build version fixed at 1 likely due to a shallow clone.")
    endif()

    execute_process(COMMAND ${GIT_EXE} rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GGML_BUILD_COMMIT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif()


# Capture variables prefixed with GGML_.

set(variable_set_statements
"
####### Expanded from @GGML_VARIABLES_EXPANED@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run        #######

")

set(GGML_SHARED_LIB ${BUILD_SHARED_LIBS})

get_cmake_property(all_variables VARIABLES)
foreach(variable_name IN LISTS all_variables)
    if(variable_name MATCHES "^GGML_")
        string(REPLACE ";" "\\;"
               variable_value "${${variable_name}}")

        set(variable_set_statements
            "${variable_set_statements}set(${variable_name} \"${variable_value}\")\n")
    endif()
endforeach()

set(GGML_VARIABLES_EXPANDED ${variable_set_statements})

# Create the CMake package and set install location.

set(GGML_INSTALL_VERSION 0.0.${GGML_BUILD_NUMBER})
set(GGML_INCLUDE_INSTALL_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE PATH "Location of header  files")
set(GGML_LIB_INSTALL_DIR     ${CMAKE_INSTALL_LIBDIR}     CACHE PATH "Location of library files")
set(GGML_BIN_INSTALL_DIR     ${CMAKE_INSTALL_BINDIR}     CACHE PATH "Location of binary  files")

configure_package_config_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/ggml-config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/ggml-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ggml
    PATH_VARS GGML_INCLUDE_INSTALL_DIR
              GGML_LIB_INSTALL_DIR
              GGML_BIN_INSTALL_DIR)

write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/ggml-version.cmake
    VERSION ${GGML_INSTALL_VERSION}
    COMPATIBILITY SameMajorVersion)

target_compile_definitions(ggml-base PRIVATE
    GGML_VERSION="${GGML_INSTALL_VERSION}"
    GGML_COMMIT="${GGML_BUILD_COMMIT}"
)
message(STATUS "ggml version: ${GGML_INSTALL_VERSION}")
message(STATUS "ggml commit:  ${GGML_BUILD_COMMIT}")

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/ggml-config.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/ggml-version.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ggml)

if (MSVC)
    set(MSVC_WARNING_FLAGS
        /wd4005  # Macro redefinition
        /wd4244  # Conversion from one type to another type, possible loss of data
        /wd4267  # Conversion from 'size_t' to a smaller type, possible loss of data
        /wd4305  # Conversion from 'type1' to 'type2', possible loss of data
        /wd4566  # Conversion from 'char' to 'wchar_t', possible loss of data
        /wd4996  # Disable POSIX deprecation warnings
        /wd4702  # Unreachable code warnings
    )
    function(disable_msvc_warnings target_name)
        if(TARGET ${target_name})
            target_compile_options(${target_name} PRIVATE ${MSVC_WARNING_FLAGS})
        endif()
    endfunction()

    disable_msvc_warnings(ggml-base)
    disable_msvc_warnings(ggml)
    disable_msvc_warnings(ggml-cpu)
    disable_msvc_warnings(ggml-cpu-x64)
    disable_msvc_warnings(ggml-cpu-sse42)
    disable_msvc_warnings(ggml-cpu-sandybridge)
    disable_msvc_warnings(ggml-cpu-haswell)
    disable_msvc_warnings(ggml-cpu-skylakex)
    disable_msvc_warnings(ggml-cpu-icelake)
    disable_msvc_warnings(ggml-cpu-alderlake)

    if (GGML_BUILD_EXAMPLES)
        disable_msvc_warnings(common-ggml)
        disable_msvc_warnings(common)

        disable_msvc_warnings(mnist-common)
        disable_msvc_warnings(mnist-eval)
        disable_msvc_warnings(mnist-train)

        disable_msvc_warnings(gpt-2-ctx)
        disable_msvc_warnings(gpt-2-alloc)
        disable_msvc_warnings(gpt-2-backend)
        disable_msvc_warnings(gpt-2-sched)
        disable_msvc_warnings(gpt-2-quantize)
        disable_msvc_warnings(gpt-2-batched)

        disable_msvc_warnings(gpt-j)
        disable_msvc_warnings(gpt-j-quantize)

        disable_msvc_warnings(magika)
        disable_msvc_warnings(yolov3-tiny)
        disable_msvc_warnings(sam)

        disable_msvc_warnings(simple-ctx)
        disable_msvc_warnings(simple-backend)
    endif()

    if (GGML_BUILD_TESTS)
        disable_msvc_warnings(test-mul-mat)
        disable_msvc_warnings(test-arange)
        disable_msvc_warnings(test-backend-ops)
        disable_msvc_warnings(test-cont)
        disable_msvc_warnings(test-conv-transpose)
        disable_msvc_warnings(test-conv-transpose-1d)
        disable_msvc_warnings(test-conv1d)
        disable_msvc_warnings(test-conv2d)
        disable_msvc_warnings(test-conv2d-dw)
        disable_msvc_warnings(test-customop)
        disable_msvc_warnings(test-dup)
        disable_msvc_warnings(test-opt)
        disable_msvc_warnings(test-pool)
    endif ()
endif()
```

---

**File C: My Existing Overlay Attempt**
I have a file that was an attempt to create a `llama-cpp` overlay.

It may not be correct, so please review and make suggestions, especially if I can simply leverage existing patterns available in the llama.cpp official flake and related files. But it may provide clues about my past intentions, especially regarding the specific CPU optimization flags I was trying to use on my Intel Tiger Lake laptop.

```nix
# ./nixos/pkgs/llama-cpp-variants.nix
#
# This overlay provides customized `llama-cpp` packages using the external flake.
# It pulls pre-built variants for CUDA and Vulkan directly from the flake,
# and provides a CPU-optimized version by adding specific cmake flags.

inputs: final: prev: {

  # 1. CPU-optimized build
  # We take the default package and override it with CPU-specific flags
  # for maximum performance on non-GPU machines.
  llama-cpp-cpu = inputs.llama-cpp.packages.${prev.system}.default.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
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
      "-DLLAMA_BUILD_SERVER=ON"
    ];
  });

  # 2. CUDA-accelerated build
  # The flake already builds this for us.
  llama-cpp-cuda = inputs.llama-cpp.packages.${prev.system}.cuda;

  # 3. Vulkan-accelerated build
  # The flake also builds a Vulkan-enabled package.
  llama-cpp-vulkan = inputs.llama-cpp.packages.${prev.system}.vulkan;

}
```

Ultimately, I want to be able to include this official-flake-based llama-cpp in my package lists.

Either a home manager config like this:

```nix
{
  pkgs,
  ...
}: {
  # Packages
  home.packages = with pkgs;
    [
      llama-cpp
      # other packages go here
    ]
}
```

or a system nix config like this:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    llama-cpp-vulkan
      # other packages go here
  ];
}
```

---

## 3.5. Key Nix/NixOS Patterns for Analysis

Here are a few advanced Nix/NixOS patterns present in the provided files. A deep understanding of these is critical for formulating a robust and idiomatic solution.

### 1. Propagating Flake Inputs via `specialArgs`

In a NixOS flake configuration, the `inputs` (like `nixpkgs`, `home-manager`, or the target `llama-cpp` flake) are not automatically available in every imported module file.

The provided `flake.nix` uses the `specialArgs` argument of `nixosSystem` to explicitly pass the flake's `inputs` down to all modules.

**Example from `flake.nix`:**
```nix
nixosConfigurations.carbon = inputs.nixpkgs.lib.nixosSystem {
  # ...
  specialArgs = {inherit inputs outputs;};
  # ...
};
```

This allows any NixOS module in that configuration to access the flake inputs by adding `inputs` to its function signature, like so: `{ inputs, pkgs, config, ... }:`

This is the primary mechanism for making the `llama-cpp` input accessible to an overlay defined in a separate file.

### 2. The Role of `callPackage`

`callPackage` is a function that calls another function (usually one that defines a derivation), automatically passing in arguments by name from the Nixpkgs package set (`pkgs`).

**Example from `llama.cpp/scope.nix`:**
```nix
llama-cpp = self.callPackage ./package.nix { };
```

Here, `callPackage` is calling the function defined in `package.nix`. It automatically provides all the build-time dependencies like `stdenv`, `cmake`, `cudaPackages`, etc., because their names match attributes in the `pkgs` set. This is a standard pattern for making package definitions concise and reusable.

### 3. Customizing Derivations: `.override` vs. `.overrideAttrs`

There are two primary ways to customize a Nix package (a "derivation"):

-   **`.override { ... }`**: This is used to change the initial arguments passed to the package function. The `llama.cpp/package.nix` file is a function that accepts boolean arguments like `useVulkan`, `useCuda`, etc. The idiomatic way to change these is with `.override`.
    *Example:* `pkgs.llama-cpp.override { useVulkan = true; }`

-   **`.overrideAttrs (old: { ... })`**: This is a lower-level function that modifies the final set of attributes passed to `stdenv.mkDerivation`. It's more powerful but can be more brittle. It's typically used when you need to change something that isn't exposed as a top-level argument, such as `cmakeFlags`, `buildInputs`, or a `postPatch` script. The `old` argument represents the original attribute set.
    *Example:* `pkgs.llama-cpp.overrideAttrs (old: { cmakeFlags = old.cmakeFlags ++ [ "-DEXTRA_FLAG=ON" ]; })`

A robust solution should prefer `.override` when possible and use `.overrideAttrs` only when necessary.

### 4. Specialized Nixpkgs Instances

The `llama.cpp` flake creates its own instances of Nixpkgs, notably `pkgsCuda`.

**Example from `.devops/nix/nixpkgs-instances.nix`:**
```nix
pkgsCuda = import inputs.nixpkgs {
  inherit system;
  config.cudaSupport = true;
  # ...
};
```

This `pkgsCuda` is a separate version of the Nixpkgs package set where `config.cudaSupport` is enabled globally. This ensures that not just `llama.cpp` but also all of its dependencies are built with CUDA support if needed. The `llama.cpp` flake then uses this special package set to build its CUDA-enabled variant. This is an advanced but powerful technique for handling complex build matrixes.

---

## 4. The Task

Based on all the information provided in the files above, your task is to create a **detailed, step-by-step implementation plan** to achieve my goal.

Your plan should:
- Be idiomatic to modern Nix and NixOS Flakes practices.
- Result in a clean, maintainable configuration that avoids code duplication.
- Clearly explain **how to add the `llama.cpp` flake as an input** in my main `flake.nix`.
- Detail **how to create and apply a new, correct overlay**. This overlay should expose the different build variants (CPU-optimized, CUDA, Vulkan) as distinct packages.
- Show **how I would select a specific variant** (e.g., `llama-cpp-cuda`) for a particular machine's configuration.
- Recommend any cleanup actions, such as deleting old, incorrect files.

Present the final output as a clear, actionable guide, as if you were writing a project documentation file (e.g., in Markdown).
