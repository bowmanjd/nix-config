# NixOS Strategy: Implementing Hardware-Optimized llama.cpp from Official Flake

## Analysis of Current State

After analyzing your configuration files, I can see you have a well-structured NixOS flake setup with proper use of `specialArgs` to propagate inputs. Your attempted overlay in `./nixos/pkgs/llama-cpp-variants.nix` shows good understanding of the goal, but has some issues:

1. **Missing flake input**: The `llama.cpp` flake isn't declared in your main `flake.nix` inputs
2. **Incorrect override approach**: Your overlay uses `overrideAttrs` with CMake flags, but the official flake already provides the proper `.override` interface
3. **Redundant CPU optimizations**: The official flake handles CPU optimizations better through its built-in mechanisms

## Recommended Implementation Strategy

### Step 1: Add llama.cpp Flake Input

First, add the official `llama.cpp` flake as an input to your main `flake.nix`:

```nix
# flake.nix
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

    # ADD THIS: Official llama.cpp flake
    llama-cpp = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ... rest of your flake remains the same
}
```

**Reasoning**: Using `inputs.nixpkgs.follows = "nixpkgs"` ensures the llama.cpp flake uses the same nixpkgs version as your system, avoiding potential conflicts and reducing evaluation time.

### Step 2: Create Proper Hardware-Optimized Overlay

Create a new file `./nixos/overlays/llama-cpp.nix`:

```nix
# ./nixos/overlays/llama-cpp.nix
# Hardware-optimized llama.cpp variants using the official flake

{ inputs }: final: prev: {
  # Import the llama.cpp packages scope for maximum flexibility
  llamaPackages = inputs.llama-cpp.packages.${final.system};

  # Default CPU-optimized build with aggressive optimizations
  # This leverages the official flake's CPU optimization logic
  llama-cpp = inputs.llama-cpp.packages.${final.system}.default.override {
    # Enable hardware-specific optimizations
    # The official flake handles CPU feature detection automatically
    # when useVulkan, useCuda, etc. are false
    enableCurl = true;
  };

  # CPU-only build with maximum CPU optimizations
  # For machines without GPU acceleration
  llama-cpp-cpu = inputs.llama-cpp.packages.${final.system}.default.override {
    # Explicitly disable GPU backends to ensure CPU optimization focus
    useVulkan = false;
    useCuda = false;
    useRocm = false;
    enableCurl = true;
  };

  # CUDA-accelerated build for NVIDIA GPU machines
  # Uses the pre-built CUDA variant from the official flake
  llama-cpp-cuda = inputs.llama-cpp.packages.${final.system}.cuda or (
    # Fallback: build CUDA variant if not available pre-built
    inputs.llama-cpp.packages.${final.system}.default.override {
      useCuda = true;
      enableCurl = true;
    }
  );

  # Vulkan-accelerated build for broad GPU compatibility
  # Good for AMD GPUs, Intel Arc, or as NVIDIA fallback
  llama-cpp-vulkan = inputs.llama-cpp.packages.${final.system}.vulkan or (
    # Fallback: build Vulkan variant if not available pre-built
    inputs.llama-cpp.packages.${final.system}.default.override {
      useVulkan = true;
      enableCurl = true;
    }
  );

  # ROCm-accelerated build for AMD GPUs (Linux only)
  llama-cpp-rocm = inputs.llama-cpp.packages.${final.system}.rocm or (
    # Fallback: build ROCm variant if not available pre-built
    inputs.llama-cpp.packages.${final.system}.default.override {
      useRocm = true;
      enableCurl = true;
    }
  );

  # MPI-enabled builds for distributed inference
  llama-cpp-mpi-cpu = inputs.llama-cpp.packages.${final.system}.default.override {
    useMpi = true;
    enableCurl = true;
  };

  llama-cpp-mpi-cuda = inputs.llama-cpp.packages.${final.system}.default.override {
    useMpi = true;
    useCuda = true;
    enableCurl = true;
  };

  # For advanced users: expose the full llamaPackages scope
  # This allows access to individual tools like python-scripts, gguf-py, etc.
  inherit (inputs.llama-cpp.packages.${final.system}) 
    llamaPackages;
}
```

**Key Design Decisions**:
1. **Uses `.override` instead of `.overrideAttrs`**: This is the idiomatic way to customize the official flake's packages
2. **Provides fallbacks**: If pre-built variants aren't available, it builds them using `.override`
3. **Exposes llamaPackages**: Gives access to the full ecosystem (Python scripts, etc.)
4. **Hardware-agnostic naming**: Makes it easy to swap variants per machine

### Step 3: Update Your Main Flake to Use the Overlay

Modify your `flake.nix` to include the new overlay:

```nix
# flake.nix (outputs section modification)
outputs = {self, ...} @ inputs: let
  inherit (self) outputs;
  overlay-stable = final: prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
  
  # ADD THIS: llama.cpp overlay
  overlay-llama-cpp = import ./nixos/overlays/llama-cpp.nix { inherit inputs; };
  
  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
  # ... rest remains the same

  in {
    nixosConfigurations = {
      carbon = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          ({
            config,
            pkgs,
            ...
          }: {
            nixpkgs.overlays = [
              overlay-stable
              overlay-llama-cpp  # ADD THIS LINE
            ];
          })
          # ... rest of your modules
        ];
      };
      
      # Repeat for other machines: beryllium, boron, nitrogen
      # (Add overlay-llama-cpp to each machine's nixpkgs.overlays)
    };
  };
```

### Step 4: Configure Per-Machine Hardware Optimization

Now you can select the appropriate variant in each machine's configuration:

#### For GPU Machines (e.g., `./machines/nitrogen.nix` - NVIDIA GPU):
```nix
# ./machines/nitrogen.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # System packages - CUDA-optimized for NVIDIA GPU
  environment.systemPackages = with pkgs; [
    llama-cpp-cuda  # Hardware-accelerated for NVIDIA
    # ... other packages
  ];

  # Optional: Enable CUDA support system-wide
  nixpkgs.config.cudaSupport = true;
  nixpkgs.config.allowUnfree = true; # CUDA requires unfree

  # ... rest of machine config
}
```

#### For CPU-only Machines (e.g., `./machines/carbon.nix` - Framework laptop):
```nix
# ./machines/carbon.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # System packages - CPU-optimized for Intel Tiger Lake
  environment.systemPackages = with pkgs; [
    llama-cpp-cpu  # Maximum CPU optimization, no GPU
    # ... other packages
  ];

  # ... rest of machine config
}
```

#### For AMD GPU Machines (e.g., `./machines/boron.nix`):
```nix
# ./machines/boron.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # System packages - Vulkan or ROCm optimized for AMD GPU
  environment.systemPackages = with pkgs; [
    llama-cpp-vulkan  # Good compatibility across vendors
    # or llama-cpp-rocm for AMD-specific optimization
    # ... other packages
  ];

  # Optional: Enable ROCm support if using llama-cpp-rocm
  # nixpkgs.config.rocmSupport = true;

  # ... rest of machine config
}
```

#### For Home Manager Users:
```nix
# In any home-manager configuration
{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    llama-cpp        # Default optimized build
    # or llama-cpp-cuda, llama-cpp-vulkan, etc.
  ];
}
```

### Step 5: Advanced CPU Optimization (Optional)

If you need even more aggressive CPU optimizations beyond what the official flake provides, you can create a specialized overlay:

```nix
# ./nixos/overlays/llama-cpp-extreme-cpu.nix
# Only use this if the default CPU optimization isn't sufficient

{ inputs }: final: prev: {
  # Extremely aggressive CPU-optimized build
  # WARNING: This may not be portable across different CPU architectures
  llama-cpp-extreme-cpu = inputs.llama-cpp.packages.${final.system}.default.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
      # Force enable all x86_64 extensions (use with caution!)
      "-DGGML_AVX=ON"
      "-DGGML_AVX2=ON" 
      "-DGGML_AVX512=ON"
      "-DGGML_AVX512_VBMI=ON"
      "-DGGML_AVX512_VNNI=ON"
      "-DGGML_AVX512_BF16=ON"
      "-DGGML_FMA=ON"
      "-DGGML_F16C=ON"
      "-DGGML_BMI2=ON"
      # Enable native optimizations (builds for current CPU only)
      "-DGGML_NATIVE=ON"
    ];
    
    # Add aggressive compiler optimizations
    NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -march=native -mtune=native -O3";
  });
}
```

**Use this only if**: The default CPU optimization isn't sufficient and you're building for a specific, known CPU architecture.

## Step 6: Cleanup Actions

1. **Delete the old overlay**: Remove `./nixos/pkgs/llama-cpp-variants.nix` as it's no longer needed
2. **Remove any old llama-cpp references**: If you had `llama-cpp` from nixpkgs in your package lists, remove them
3. **Test the build**: Run `nix flake check` to ensure everything evaluates correctly

## Step 7: Testing and Validation

```bash
# Test that packages are available
nix build .#nixosConfigurations.carbon.config.environment.systemPackages

# Test individual variants
nix build github:ggml-org/llama.cpp#cuda     # Test CUDA build
nix build github:ggml-org/llama.cpp#vulkan   # Test Vulkan build

# Check that your overlay is working
nix eval .#nixosConfigurations.carbon.config.nixpkgs.overlays --json
```

## Benefits of This Approach

1. **Idiomatic**: Uses the official flake's intended interfaces
2. **Maintainable**: Updates automatically when the upstream flake updates
3. **Flexible**: Easy to swap variants per machine
4. **Clean**: No code duplication, leverages upstream optimization work
5. **Future-proof**: Will benefit from improvements in the official flake

## Machine-Specific Recommendations

Based on your hardware configurations:

- **carbon & beryllium** (Framework 13 7040 AMD): Use `llama-cpp-vulkan` (good AMD GPU support) or `llama-cpp-cpu` (if no discrete GPU)
- **boron** (unknown hardware): Use `llama-cpp-cpu` as safe default, or `llama-cpp-vulkan` for broad compatibility
- **nitrogen** (unknown hardware): Use `llama-cpp-cuda` if NVIDIA GPU, `llama-cpp-vulkan` for AMD GPU, `llama-cpp-cpu` otherwise

This strategy gives you hardware-optimized builds while maintaining clean, maintainable code that follows NixOS best practices.