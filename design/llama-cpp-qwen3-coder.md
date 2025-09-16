# NixOS Llama.cpp Overlay Strategy: A Step-by-Step Guide

This document provides a comprehensive plan to integrate the official `llama.cpp` flake into your NixOS configuration, enabling optimized builds for different hardware profiles.

## 1. Add the llama.cpp flake as an input

First, we need to add the `llama.cpp` flake to your main `flake.nix` inputs. This will allow you to reference it throughout your configuration.

### Updated `flake.nix` inputs section:

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

    # Llama.cpp flake
    llama-cpp = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  # ... rest of your flake remains unchanged
}
```

## 2. Create a new overlay for llama.cpp variants

We'll create a clean, modular overlay that leverages the official flake's capabilities while adding hardware-specific optimizations.

### Create `./nixos/pkgs/llama-cpp-overlay.nix`:

```nix
# ./nixos/pkgs/llama-cpp-overlay.nix
{ inputs, ... }:

final: prev: {
  # CPU-optimized build with aggressive optimizations
  llama-cpp-cpu = inputs.llama-cpp.packages.${prev.system}.default.override {
    # Rely on Nixpkgs' native optimizations rather than GGML's detection
    # Nixpkgs already handles CPU-specific optimizations well
  };

  # CUDA-accelerated build
  llama-cpp-cuda = inputs.llama-cpp.packages.${prev.system}.cuda;

  # Vulkan-accelerated build
  llama-cpp-vulkan = inputs.llama-cpp.packages.${prev.system}.vulkan;

  # ROCm-accelerated build (for AMD GPUs)
  llama-cpp-rocm = inputs.llama-cpp.packages.${prev.system}.rocm or 
    (inputs.llama-cpp.packages.${prev.system}.default.override { useRocm = true; });
}
```

## 3. Apply the overlay in your flake configuration

We'll modify your flake to include the new overlay. This approach maintains your existing structure while adding the new functionality.

### Updated flake module definition (in each nixosConfiguration):

```nix
# In each nixosConfiguration (carbon, beryllium, etc.)
modules = [
  ({
    config,
    pkgs,
    ...
  }: {
    nixpkgs.overlays = [
      overlay-stable
      (import ./nixos/pkgs/llama-cpp-overlay.nix { inherit inputs; })
    ];
  })
  # ... rest of your modules
]
```

## 4. Create hardware-specific configurations

Now we'll create machine-specific configurations that select the appropriate llama.cpp variant based on hardware capabilities.

### Create `./machines/hardware-profiles/` directory with profile files:

#### `./machines/hardware-profiles/cuda.nix`:
```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-cuda
  ];
}
```

#### `./machines/hardware-profiles/vulkan.nix`:
```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-vulkan
  ];
}
```

#### `./machines/hardware-profiles/cpu-optimized.nix`:
```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-cpu
  ];
}
```

## 5. Update machine configurations to use hardware profiles

Modify your existing machine configuration files to include the appropriate hardware profile.

### Example for `./machines/carbon.nix` (NVIDIA GPU machine):
```nix
{ ... }:
{
  imports = [
    ./hardware-profiles/cuda.nix
    # ... other imports
  ];
  
  # Your existing carbon-specific configuration
}
```

### Example for a Vulkan machine:
```nix
{ ... }:
{
  imports = [
    ./hardware-profiles/vulkan.nix
    # ... other imports
  ];
  
  # Your machine-specific configuration
}
```

### Example for a CPU-only machine:
```nix
{ ... }:
{
  imports = [
    ./hardware-profiles/cpu-optimized.nix
    # ... other imports
  ];
  
  # Your machine-specific configuration
}
```

## 6. Advanced optimizations (optional)

For even more fine-grained control, you can create specialized overlays for specific CPU architectures.

### Create `./nixos/pkgs/advanced-llama-overlay.nix`:
```nix
{ inputs, ... }:

final: prev: {
  # Intel Tiger Lake optimized build
  llama-cpp-tiger-lake = inputs.llama-cpp.packages.${prev.system}.default.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
      "-DGGML_SSE42=ON"
      "-DGGML_AVX=ON"
      "-DGGML_F16C=ON"
      "-DGGML_AVX2=ON"
      "-DGGML_BMI2=ON"
      "-DGGML_FMA=ON"
      "-DGGML_AVX512=ON"
      "-DGGML_AVX512_VBMI=ON"
      "-DGGML_AVX512_VNNI=ON"
    ];
  });

  # AMD Ryzen optimized build
  llama-cpp-ryzen = inputs.llama-cpp.packages.${prev.system}.default.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
      "-DGGML_AVX2=ON"
      "-DGGML_FMA=ON"
      "-DGGML_F16C=ON"
      "-DGGML_AVX512=ON"
      "-DGGML_AMX_BF16=ON"
    ];
  });
}
```

## 7. Home Manager Integration

To use llama.cpp in Home Manager configurations, you can reference the packages directly:

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    llama-cpp-cuda  # or llama-cpp-vulkan, llama-cpp-cpu
  ];
}
```

## 8. Cleanup recommendations

1. Delete the old overlay file at `./nixos/pkgs/llama-cpp-variants.nix`
2. Ensure all machine configurations properly import their hardware profiles
3. Test each configuration individually to verify the correct variant is being used

## 9. Verification

To verify your setup is working correctly:

1. Check that the flake evaluates:
   ```bash
   nix flake check
   ```

2. Build a specific variant:
   ```bash
   nix build .#nixosConfigurations.carbon.config.environment.systemPackages.llama-cpp-cuda
   ```

3. Check the build flags:
   ```bash
   nix eval .#nixosConfigurations.carbon.config.environment.systemPackages.llama-cpp-cuda.cmakeFlags
   ```

This approach provides a clean, maintainable solution that leverages the official llama.cpp flake while allowing for hardware-specific optimizations. Each machine configuration clearly indicates which variant it's using, making the system easy to understand and modify.