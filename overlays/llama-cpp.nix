# File: ./nixos/overlays/llama-cpp.nix
#
# This overlay provides a comprehensive set of `llama-cpp` packages using the
# official `llama-cpp` flake. It provides standard builds and versions that are
# additionally optimized for the host CPU's native instruction set (AVX, FMA, etc.).
{
  inputs,
  lib,
  ...
}: final: prev: let
  system = prev.system;

  # Helper function to apply native CPU optimizations to any llama.cpp package.
  # This avoids repeating the same overrideAttrs logic for each variant.
  withNativeCpu = pkg:
    pkg.overrideAttrs (old: {
      # Append a suffix for clarity in the Nix store path
      pname = old.pname + "-native";

      # Remove the generic flag and add the native optimization flag.
      cmakeFlags =
        (lib.lists.filter (flag: flag != "-DGGML_NATIVE=false") old.cmakeFlags)
        ++ [
          "-DGGML_NATIVE=ON"
        ];
      NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -O3 -march=native -mtune=native";
      NIX_CXXSTDLIB_COMPILE = (old.NIX_CXXSTDLIB_COMPILE or "") + " -O3 -march=native -mtune=native";
    });
in {
  # --- Base Packages (Portable builds) ---

  # 1. Base CPU-only package from the upstream flake's overlay.
  llama-cpp-cpu = (inputs.llama-cpp.overlays.default final prev).llamaPackages.llama-cpp;

  # 2. Base Vulkan-accelerated package.
  llama-cpp-vulkan = final.llama-cpp-cpu.override {useVulkan = true;};

  # 3. Base CUDA-accelerated package.
  # This one is special, as it comes from the flake's CUDA-specific pkgs set.
  llama-cpp-cuda = inputs.llama-cpp.legacyPackages.${system}.llamaPackagesCuda.llama-cpp;

  # --- Native-Optimized Packages ---

  # 1n. Native-optimized CPU-only package.
  llama-cpp-cpu-native = withNativeCpu final.llama-cpp-cpu;

  # 2n. Native-optimized Vulkan package (for Intel/AMD GPUs).
  llama-cpp-vulkan-native = withNativeCpu final.llama-cpp-vulkan;

  # 3n. Native-optimized CUDA package (for NVIDIA GPUs).
  llama-cpp-cuda-native = withNativeCpu final.llama-cpp-cuda;

  # --- A Sensible Default ---

  # For convenience, `pkgs.llama-cpp` will point to the most common optimized build.
  # Anyone building from source on their own machine likely wants this.
  llama-cpp = final.llama-cpp-cpu-native;
}
