

# Advanced NixOS Strategy: Integrating Official llama.cpp with Hardware-Specific Builds

## Introduction
This document outlines a clean, maintainable strategy to replace the standard `llama-cpp` package with the official `ggml-org/llama.cpp` flake source while providing hardware-specific optimizations for your NixOS fleet. The solution leverages modern Nix/NixOS Flakes patterns to avoid code duplication and ensure optimal performance on every machine type.

## Core Principles
- **Hardware-specific variants**: Use distinct package names for different acceleration backends (`llama-cpp`, `llama-cpp-cuda`, `llama-cpp-vulkan`)
- **Runtime CPU detection**: Rely on `ggml`'s built-in runtime CPU feature detection instead of hardcoded build flags
- **Idiomatic overlays**: Use simple overlays to expose flake packages cleanly
- **Minimal configuration**: Leverage flake inputs directly without manual overrides

## Step-by-Step Implementation Plan

### 1. Add llama.cpp as a Flake Input
Modify your root `flake.nix` to include the official `llama.cpp` flake as a dependency:

```nix
# In your root flake.nix's inputs section:
{
  # ... existing inputs ...
  
  llama-cpp = {
    url = "github:ggml-org/llama.cpp";
    inputs.nixpkgs.follows = "nixpkgs";  # Share your Nixpkgs version
    flake = true;
  };
}
```

**Why this works:**
- Uses the same Nixpkgs version as your main flake (via `inputs.nixpkgs.follows`)
- Ensures consistent dependencies across all systems
- Properly references the official flake structure

### 2. Create a Minimal Overlay for Package Exposure
Define a simple overlay in your root flake's `outputs` section:

```nix
# In your root flake.nix's outputs section:
{
  description = "...";
  
  inputs = { ... };  # as defined above
  
  outputs = { self, ... } @ inputs: let
    # ... existing overlay-stable and systems definitions ...
    
    # NEW: llama.cpp overlay definition
    llama-overlay = final: prev: {
      llama-cpp      = inputs.llama-cpp.packages.${prev.system}.default;
      llama-cpp-cuda = inputs.llama-cpp.packages.${prev.system}.cuda;
      llama-cpp-vulkan = inputs.llama-cpp.packages.${prev.system}.vulkan;
      # Add others like rocm if needed later: 
      # llama-cpp-rocm = inputs.llama-cpp.packages.${prev.system}.rocm;
    };

  in {
    nixosConfigurations = {
      carbon = inputs.nixpkgs.lib.nixosSystem {
        # ... existing configuration ...
        modules = [
          ({
            config,
            pkgs,
            ...
          }: {
            nixpkgs.overlays = [
              overlay-stable
              llama-overlay  # Apply the new overlay
            ];
          })
          # ... existing machine-specific modules ...
        ];
      };
      # Repeat for all machines with the SAME overlay addition
      beryllium = # ... same pattern ...
      boron = # ... same pattern ...
      nitrogen = # ... same pattern ...
    };
  };
}
```

**Why this overlay is correct:**
- No manual derivation overrides needed
- Uses the official flake's pre-built variants:
  - `.default`: CPU-only with runtime detection
  - `.cuda`: NVIDIA GPU accelerated
  - `.vulkan`: Vulkan API accelerated
- Automatically resolves the system correctly via `${prev.system}`
- Zero build-time flags - relies on `ggml`'s built-in runtime CPU detection

### 3. Configure Hardware-Specific Usage Per Machine
Update each machine's configuration file to select the appropriate package variant:

#### For NVIDIA GPU Machines (e.g., `machines/carbon.nix`)
```nix
{
  environment.systemPackages = with pkgs; [
    # Other system packages...
    llama-cpp-cuda  # Uses CUDA-accelerated build
  ];
}
```

#### For CPU-Only Machines (e.g., `machines/boron.nix`)
```nix
{
  environment.systemPackages = with pkgs; [
    # Other system packages...
    llama-cpp  # Uses CPU-only with runtime detection
  ];
}
```

#### For Vulkan GPU Machines (e.g., `machines/nitrogen.nix`)
```nix
{
  environment.systemPackages = with pkgs; [
    # Other system packages...
    llama-cpp-vulkan  # Uses Vulkan-accelerated build
  ];
}
```

### 4. Clean Up Old Configuration Artifacts
```bash
# Delete the incorrect overlay attempt
rm nixos/pkgs/llama-cpp-variants.nix

# Remove any legacy overrides from your machine configurations
# (e.g., remove any llama-cpp overrides with custom cmakeFlags)
```

## Why This Strategy Works Perfectly

### 1. No CPU Flag Hardcoding Needed
- **Problem**: Your initial overlay attempt tried to manually set `-DGGML_AVX512=ON` etc.
- **Solution**: The `ggml` library has **built-in runtime CPU feature detection** for all instruction sets. 
- **Why it's safe**: 
  - When built with `GGML_NATIVE=OFF` (default in llama.cpp flake), it includes all instruction set kernels
  - At runtime, the library checks CPUID and selects the fastest available implementation
  - This works reliably across different CPU generations without rebuilds
  - No risk of illegal instruction crashes (common when hardcoding build flags for specific CPUs)

### 2. Leverages Official Flake's Specialization
- The `llama.cpp` flake already creates:
  - `cuda` variant using specialized `pkgsCuda` Nixpkgs instance
  - `vulkan` variant with proper Vulkan dependency chain
  - `default` variant with BLAS acceleration where available
- Your overlay simply exposes these pre-built variants without modification

### 3. Perfect Integration with Your Existing Flakes Architecture
- Uses `specialArgs` as you already have configured it
- Properly shares your main Nixpkgs version (via `inputs.nixpkgs.follows`)
- Maintains your existing overlay pattern with `overlay-stable`
- Minimal changes to your current structure

### 4. Hardware-Specific Deployment Made Simple
- Each machine explicitly declares which variant to use based on its actual hardware
- No need for conditional logic in the main configuration
- Clear semantic naming (`llama-cpp-cuda` is obviously for CUDA)
- Easy to extend later (e.g., add `llama-cpp-rocm` for ROCm machines)

## Critical Safety Notes

### ⚠️ Never Override Build Flags Manually
The `package.nix` in llama.cpp intentionally:
- Sets `GGML_NATIVE = false` to prevent host-dependent builds
- Uses runtime detection instead of hard-coded instruction sets
- Manually overriding flags like `-DGGML_AVX512=ON` will:
  - Break on machines without that instruction set
  - Increase binary size unnecessarily
  - Create reproducibility issues

### 🔌 CUDA/Vulkan Specific Requirements
- **For CUDA machines**: Ensure you have:
  - NVIDIA drivers installed via NixOS module
  - Proper GPU firmware
  - Correct kernel parameters (if needed)
- **For Vulkan machines**: Ensure:
  - `hardware.opengl.enable = true;` in your config
  - Correct Mesa/Vulkan drivers for your GPU

## Verification Steps

After implementing this solution:

1. Run `nix flake check` to validate all configurations
2. For each machine type:
   ```bash
   # Check for CUDA-enabled build
   nix run .#nixosConfigurations.carbon.packages.llama-cpp-cuda -- --version | grep CUDA
   
   # Check CPU-only variant
   nix run .#nixosConfigurations.boron.packages.llama-cpp -- --version | grep -v "CUDA\|Vulkan"
   
   # Check Vulkan variant
   nix run .#nixosConfigurations.nitrogen.packages.llama-cpp-vulkan -- --version | grep Vulkan
   ```
3. Verify the binary size is reasonable (~20-30MB for CPU-only)
4. Run a test inference on all machine types to confirm functionality

## Summary of Key Benefits
- ✅ No custom build flags needed - uses correct built-in runtime detection
- ✅ Zero code duplication across machines
- ✅ Clear semantic naming for each hardware variant
- ✅ Fully integrated with your existing flake architecture
- ✅ Follows NixOS best practices for package specialization
- ✅ Safe across all CPU generations without crashes
- ✅ Minimal maintenance overhead for future updates

This solution provides the cleanest, most reliable way to use llama.cpp across diverse hardware configurations while fully leveraging the official package repository's expertise. You can now confidently deploy optimized builds across your entire fleet with minimal configuration complexity.