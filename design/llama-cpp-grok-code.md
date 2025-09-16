# NixOS Strategy for Integrating Official llama.cpp Flake

## Overview

This guide outlines a step-by-step plan to replace the standard `nixpkgs` `llama-cpp` package with builds from the official `llama.cpp` flake (`github:ggml-org/llama.cpp`). The solution leverages the flake's built-in support for hardware-optimized variants (CUDA, Vulkan, ROCm, and CPU) while adding per-machine CPU optimizations. It emphasizes modularity, idiomatic Nix patterns, and avoids duplication by reusing the flake's overlays and package logic.

Key principles:
- **Modularity**: Use overlays to expose variants as distinct packages (e.g., `llama-cpp-cpu`, `llama-cpp-cuda`).
- **Hardware-Specific Builds**: Select variants based on machine capabilities (e.g., CUDA for NVIDIA, Vulkan as fallback, CPU-only otherwise).
- **CPU Optimizations**: Enable `GGML_NATIVE` and set architecture-specific flags (e.g., AVX, AVX512) for all builds, overriding the flake's default of `GGML_NATIVE=false`.
- **Idiomatic Nix**: Prefer `.override` over `.overrideAttrs` where possible; use `specialArgs` to propagate inputs; leverage the flake's `pkgsCuda` and `pkgsRocm` instances.
- **Cleanup**: Remove outdated files like your existing `./nixos/pkgs/llama-cpp-variants.nix`.

## Step 1: Add the llama.cpp Flake as an Input

Update your root `flake.nix` to include the `llama.cpp` flake. This makes it available via `inputs.llama-cpp`.

### Changes to `flake.nix`

1. Add the input:
   ```nix
   inputs = {
     # ... existing inputs ...
     llama-cpp.url = "github:ggml-org/llama.cpp";
     # Follow nixpkgs to avoid version mismatches
     llama-cpp.inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

2. No changes needed to `outputs` or `specialArgs`—the existing propagation via `specialArgs = {inherit inputs outputs;};` will make `inputs.llama-cpp` accessible in modules and overlays.

3. **Rationale**: This follows the pattern in your flake (e.g., how `waybar` follows `nixpkgs`). It ensures compatibility and avoids redundant Nixpkgs instances.

## Step 2: Create a New Overlay for llama.cpp Variants

Replace your existing `./nixos/pkgs/llama-cpp-variants.nix` (which has issues, such as assuming flake packages are already in `inputs.llama-cpp.packages.${system}` without proper overlay application). Create a new file: `./nixos/overlays/llama-cpp.nix`.

This overlay:
- Applies the official flake's overlay to inject `llamaPackages` into `pkgs`.
- Defines variants by overriding the base package with hardware-specific flags and CPU optimizations.
- Uses the flake's specialized instances (e.g., `pkgsCuda`) for CUDA/ROCm builds.

### New File: `./nixos/overlays/llama-cpp.nix`

```nix
# ./nixos/overlays/llama-cpp.nix
# Overlay to provide optimized llama.cpp variants from the official flake.
{ inputs, ... }:

final: prev:
let
  # Apply the official llama.cpp overlay to get llamaPackages
  llamaOverlay = inputs.llama-cpp.overlays.default;
  pkgsWithLlama = llamaOverlay final prev;
  llamaPackages = pkgsWithLlama.llamaPackages;

  # Helper to add aggressive CPU optimizations to any variant
  # Enables GGML_NATIVE and sets architecture-specific flags.
  # Assumes x86_64; adjust for ARM if needed.
  withCpuOptimizations = pkg: pkg.override {
    useBlas = true;  # Enable BLAS for better CPU perf
  } // {
    # Override attrs to add CPU flags (since .override doesn't expose cmakeFlags directly)
    overrideAttrs = f: pkg.overrideAttrs (old: {
      cmakeFlags = old.cmakeFlags ++ [
        "-DGGML_NATIVE=ON"  # Enable native CPU optimizations
        "-DGGML_SSE42=ON"
        "-DGGML_AVX=ON"
        "-DGGML_F16C=ON"
        "-DGGML_AVX2=ON"
        "-DGGML_BMI2=ON"
        "-DGGML_FMA=ON"
        "-DGGML_AVX512=ON"
        "-DGGML_AVX512_VBMI=ON"
        "-DGGML_AVX512_VNNI=ON"
        "-DGGML_OPENMP=ON"  # Multi-threading
        "-DLLAMA_BUILD_SERVER=ON"  # Include server binary
      ];
    } // (f old));
  };
in
{
  # Base CPU-optimized package (fallback for all machines)
  llama-cpp-cpu = withCpuOptimizations llamaPackages.llama-cpp;

  # CUDA-accelerated (for NVIDIA GPUs)
  # Uses the flake's cuda package, which leverages pkgsCuda
  llama-cpp-cuda = withCpuOptimizations llamaPackages.cuda;

  # Vulkan-accelerated (for non-NVIDIA GPUs)
  llama-cpp-vulkan = withCpuOptimizations (llamaPackages.llama-cpp.override { useVulkan = true; });

  # ROCm-accelerated (for AMD GPUs on Linux x86_64)
  llama-cpp-rocm = if prev.stdenv.isLinux && prev.system == "x86_64-linux"
    then withCpuOptimizations llamaPackages.rocm
    else null;  # Not supported elsewhere
}
```

### Integration into `flake.nix`

1. Add the overlay to your `overlays` list in the `outputs` section (after `overlay-stable`):
   ```nix
   overlay-stable = final: prev: {
     stable = import inputs.nixpkgs-stable {
       system = final.system;
       config.allowUnfree = true;
     };
   };
   overlay-llama-cpp = import ./nixos/overlays/llama-cpp.nix { inherit inputs; };
   ```

2. In each `nixosConfiguration`, apply it in the module list:
   ```nix
   nixosConfigurations.carbon = inputs.nixpkgs.lib.nixosSystem {
     # ... other args ...
     modules = [
       ({
         config,
         pkgs,
         ...
       }: {
         nixpkgs.overlays = [
           overlay-stable
           overlay-llama-cpp  # Add this
         ];
       })
       # ... rest of modules ...
     ];
   };
   ```
   Repeat for other machines (beryllium, boron, nitrogen).

3. **Rationale**:
   - **Overlay Application**: We apply the official flake's overlay first to get `llamaPackages`, then customize.
   - **CPU Optimizations**: Overrides `GGML_NATIVE=false` (from package.nix) to `true` and adds flags. This ensures aggressive optimizations (detected at build-time) without hardcoding microarchitecture.
   - **Hardware Variants**: CUDA uses `llamaPackages.cuda` (built with `pkgsCuda`). Vulkan overrides `useVulkan`. This matches the flake's patterns.
   - **Modularity**: Variants are exposed as top-level packages, making them easy to reference in configs.
   - **Per-Machine Selection**: See Step 3 for how to choose variants.

## Step 3: Select Variants per Machine

In each machine's NixOS config (e.g., `./machines/carbon.nix`), reference the appropriate variant based on hardware. Use `pkgs.llama-cpp-<variant>`.

### Example Configurations

- **For carbon (NVIDIA GPU)**: Use CUDA.
  ```nix
  # ./machines/carbon.nix
  { config, lib, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      llama-cpp-cuda  # CUDA-accelerated
      # ... other packages ...
    ];
  }
  ```

- **For beryllium (AMD GPU or Vulkan-capable)**: Use Vulkan.
  ```nix
  # ./machines/beryllium.nix
  { config, lib, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      llama-cpp-vulkan  # Vulkan-accelerated
      # ... other packages ...
    ];
  }
  ```

- **For boron/nitrogen (CPU-only or unknown GPU)**: Use CPU-optimized.
  ```nix
  # ./machines/boron.nix (or nitrogen.nix)
  { config, lib, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      llama-cpp-cpu  # CPU-optimized with AVX/etc.
      # ... other packages ...
    ];
  }
  ```

- **For Home Manager**: In a home-manager module, use the same packages (e.g., `home.packages = with pkgs; [ llama-cpp-vulkan ];`).

### Rationale
- **Hardware Detection**: Assume you know your machines' capabilities (e.g., via `lspci` or `nvidia-smi`). If dynamic detection is needed, add logic to check GPU presence (e.g., via `config.hardware.nvidia.enable`), but keep it simple for now.
- **All Variants Optimized**: `withCpuOptimizations` applies to every variant, ensuring CPU flags regardless of GPU backend.
- **Fallback**: CPU variant is safe for all; upgrade to GPU variants where beneficial.

## Step 4: Cleanup and Testing

1. **Delete Old Files**:
   - Remove `./nixos/pkgs/llama-cpp-variants.nix`—it's incorrect and superseded.

2. **Test Builds**:
   - Run `nix build .#carbon` (or equivalent) to build the full config.
   - Verify packages: `nix run .#carbon#llama-cpp-cuda` should launch the optimized binary.
   - Check optimizations: Run `llama-cli --help` and inspect logs for enabled features (e.g., AVX512).

3. **Potential Issues and Fixes**:
   - **CUDA/ROCm Licensing**: Ensure `config.allowUnfree = true;` in NixOS config for NVIDIA/AMD drivers.
   - **Build Failures**: If CPU flags cause issues (e.g., on ARM), add system checks in the overlay.
   - **Performance Verification**: Benchmark with a model to confirm optimizations (e.g., compare inference speed).
   - **Updates**: Pin the flake if needed (e.g., `llama-cpp.url = "github:ggml-org/llama.cpp/abc123";`).

This approach is maintainable, leverages the official flake's strengths, and scales across your fleet. If issues arise, consult the llama.cpp flake's documentation or NixOS forums.