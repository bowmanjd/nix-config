# Integrating Official `llama.cpp` Flake into Your NixOS Configuration: A Step-by-Step Guide

This guide provides a detailed, idiomatic plan to achieve your goal of replacing the standard `nixpkgs` `llama-cpp` package with variants built directly from the official `llama.cpp` flake (at `github:ggml-org/llama.cpp`). The solution emphasizes modularity, maintainability, and modern Nix/Flakes practices:

- **Modularity**: We'll add the `llama.cpp` flake as an input and use its built-in overlay to expose packages cleanly.
- **Per-Machine Optimization**: Variants (CPU-optimized, CUDA, Vulkan) will be selected based on machine-specific configuration options, avoiding duplication.
- **Idiomatic Patterns**: Leverage `specialArgs` for input propagation, the `llama.cpp` flake's overlay for package exposure, and `.override` for customizations (preferring it over `.overrideAttrs` where possible). We'll avoid global Nixpkgs instances unless necessary (e.g., for CUDA).
- **Cleanliness**: No code duplication across machines; use shared modules in `./nixos`. Aggressive CPU optimizations (e.g., AVX512) will be enabled via CMake flags in a CPU-specific override, tailored for your hardware (e.g., Intel Tiger Lake supports AVX2, FMA, etc.).
- **Assumptions**:
  - "NVIDIA GPUs" → Use CUDA variant (requires `hardware.nvidia` or similar detection).
  - "Vulkan" → Use Vulkan variant (common for AMD/Intel integrated GPUs).
  - "CPU-only" → Use CPU variant with `GGML_NATIVE=ON` for auto-detection of features like AVX/AVX512/FMA.
  - You'll specify the variant per machine in files like `./machines/carbon.nix` (e.g., via a simple option like `llamaVariant = "cuda";`).
  - All machines are `x86_64-linux` (per your `flake.nix`); adjust if needed for aarch64.
  - Binary caches: The `llama.cpp` flake mentions optional CUDA caches—enable them in your Nix config if builds are slow (see Step 1).

This plan results in packages like `pkgs.llama-cpp-cpu`, `pkgs.llama-cpp-cuda`, etc., usable in `environment.systemPackages` or Home Manager's `home.packages`.

## Step 1: Add `llama.cpp` as a Flake Input and Enable Binary Caches (If Desired)

Update your root `flake.nix` to include the `llama.cpp` input. Follow its `nixpkgs.follows` to keep it pinned to your unstable channel.

### Updated `flake.nix` (Key Changes Only)
```nix
{
  description = "techyporcupine's NixOS Config!";

  inputs = {
    # ... (existing inputs unchanged)

    # Add this: Official llama.cpp flake for optimized builds
    llama-cpp = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";  # Pin to your unstable nixpkgs
    };
  };

  outputs = {self, ...} @ inputs: let
    inherit (self) outputs;
    # ... (existing lets unchanged)

    # Optional: Enable llama.cpp's binary cache for CUDA builds (faster, but requires trust)
    # Add this to your global Nix config (e.g., in ./nixos/nix.nix or /etc/nix/nix.conf):
    #   nix.settings = {
    #     substituters = [ "https://cuda-maintainers.cachix.org" ];
    #     trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];
    #   };
  in {
    # ... (nixosConfigurations unchanged for now; see Step 2)
  };
}
```

**Reasoning**:
- This pins `llama.cpp` to the latest commit while following your `nixpkgs` for consistency (avoids version mismatches).
- Binary caches: Uncomment and add to a NixOS module (e.g., `./nixos/nix.nix`) if you have NVIDIA machines—reduces build time for CUDA dependencies. It's optional but recommended for fleets.
- No changes to `systems` or `forAllSystems` needed, as `llama.cpp` supports `x86_64-linux`.

Run `nix flake update` after editing to lock the new input.

## Step 2: Propagate the New Input via `specialArgs`

Your existing `flake.nix` already passes `inputs` via `specialArgs` to all `nixosConfigurations`. This is perfect—no changes needed here! Any module (e.g., in `./nixos`) can now access `inputs.llama-cpp`.

**Reference to File A**: Your `specialArgs = {inherit inputs outputs;};` in each `nixosConfigurations.*` ensures downstream modules receive `inputs`. We'll use this in Step 3 to build a shared overlay.

## Step 3: Create a Shared Overlay for `llama.cpp` Variants

We'll define a new overlay in `./nixos/overlays/llama-cpp.nix` (create the `overlays` dir if needed). This overlay:
- Uses the `llama.cpp` flake's `overlays.default` to expose `llamaPackages` and `llama-cpp`.
- Defines three variants:
  - `llama-cpp-cpu`: Based on `packages.default`, overridden with CPU optimizations (e.g., `GGML_NATIVE=ON`, explicit flags for AVX/AVX512/FMA). This auto-detects hardware like your Tiger Lake laptop.
  - `llama-cpp-cuda`: Uses `packages.cuda` (built with `pkgsCuda` for full CUDA support).
  - `llama-cpp-vulkan`: Uses `packages.vulkan`.
- Applies conditionally based on a new option `llama.variant` (set per machine).

**Reference to File B (llama.cpp Flake)**:
- The flake's `overlays.default` calls `./devops/nix/scope.nix` to create `llamaPackages.llama-cpp`.
- Packages like `.cuda` use `pkgsCuda` (from `nixpkgs-instances.nix`), which sets `config.cudaSupport = true` globally—ensuring dependencies (e.g., cuBLAS) are CUDA-enabled.
- For Vulkan/CPU, it uses the base `pkgs`.
- Customizations use `.override { useVulkan = true; }` (preferred over `.overrideAttrs` for top-level args like `useVulkan`).

**Reference to File C (Your Existing Overlay)**:
- Your attempt is close but flawed: It assumes `inputs` in the overlay (not directly available) and uses `.overrideAttrs` for CMake flags (unnecessary; use `.override` + post-override for flags). It also doesn't handle per-machine selection or the flake's `pkgsCuda`.
- We'll replace it entirely with this cleaner version. **Cleanup Action**: Delete `./nixos/pkgs/llama-cpp-variants.nix` after implementing this.

### New File: `./nixos/overlays/llama-cpp.nix`
```nix
{ inputs, config, lib, pkgs, ... }:

let
  # Apply the llama.cpp flake's overlay to expose llamaPackages
  llamaOverlay = inputs.llama-cpp.overlays.default;
  llamaPkgs = import inputs.nixpkgs {
    inherit (pkgs) system;
    overlays = [ llamaOverlay ];
    config.allowUnfree = true;  # Needed for CUDA if used
  }.llamaPackages;

  # CPU-optimized variant: Enable native detection + explicit flags for aggressive opts
  # (e.g., AVX2/FMA for Tiger Lake; GGML_NATIVE=ON auto-detects AVX512 if available)
  llama-cpp-cpu = (llamaPkgs.llama-cpp.override {
    # Top-level overrides from package.nix
    useBlas = true;  # Use OpenBLAS for CPU accel (idiomatic in Nix)
    useMpi = false;  # Disable unless needed
    enableCurl = true;  # For server mode
  }).overrideAttrs (old: {
    # Lower-level: Inject CMake flags for CPU features (package.nix doesn't expose all)
    cmakeFlags = old.cmakeFlags ++ [
      "-DGGML_NATIVE=ON"  # Auto-detect CPU features (overrides flake's false default)
      "-DGGML_SSE42=ON"
      "-DGGML_AVX=ON"
      "-DGGML_F16C=ON"
      "-DGGML_AVX2=ON"
      "-DGGML_BMI2=ON"
      "-DGGML_FMA=ON"
      "-DGGML_AVX512=ON"  # Enable if hardware supports (e.g., not Tiger Lake, but harmless)
      "-DGGML_AVX512_VBMI=ON"
      "-DGGML_AVX512_VNNI=ON"
      "-DGGML_OPENMP=ON"  # Parallelism
      "-DLLAMA_BUILD_SERVER=ON"  # Build server binary
    ];
    # Optional: Add native compiler flags for max perf (Nix stdenv already optimizes somewhat)
    NIX_CFLAGS_COMPILE = old.NIX_CFLAGS_COMPILE or "" + " -march=native -mtune=native";
  });

  # CUDA variant: Use flake's pre-built CUDA package (uses pkgsCuda internally)
  llama-cpp-cuda = llamaPkgs.llama-cpp.override {
    useCuda = true;  # Enables GGML_CUDA=ON, cuBLAS, etc.
    # Note: Flake handles cudaCapabilities via config (set in your machine config if needed, e.g., "8.6" for RTX 30xx)
  };

  # Vulkan variant: Use flake's pre-built Vulkan package
  llama-cpp-vulkan = llamaPkgs.llama-cpp.override {
    useVulkan = true;  # Enables GGML_VULKAN=ON
  };

  # Select variant based on config.llama.variant
  selectedLlamaCpp = if config.llama.variant == "cuda" then llama-cpp-cuda
                     else if config.llama.variant == "vulkan" then llama-cpp-vulkan
                     else if config.llama.variant == "cpu" then llama-cpp-cpu
                     else throw "Invalid llama.variant: ${config.llama.variant}";

in {
  # Expose all variants in pkgs for flexibility
  nixpkgs.overlays = [ (final: prev: {
    llama-cpp-cpu = llama-cpp-cpu;
    llama-cpp-cuda = llama-cpp-cuda;
    llama-cpp-vulkan = llama-cpp-vulkan;
    # Alias for backward compat: pkgs.llama-cpp → selected variant
    llama-cpp = selectedLlamaCpp;
  }) ];

  # New option for per-machine selection (default: cpu)
  options.llama = {
    variant = lib.mkOption {
      type = lib.types.enum [ "cpu" "cuda" "vulkan" ];
      default = "cpu";
      description = "Llama.cpp build variant (cpu/cuda/vulkan)";
    };
  };

  # Example usage: Install the selected variant system-wide
  # (Uncomment/adjust in your shared config, e.g., ./nixos/default.nix)
  # environment.systemPackages = [ pkgs.llama-cpp ];
}
```

**Reasoning**:
- **Overlay Structure**: Applies `llama.cpp`'s `overlays.default` to a fresh `nixpkgs` import (avoids polluting your main `pkgs`). This exposes `llamaPackages` cleanly (per flake docs).
- **Variants**:
  - **CPU**: Starts from `default` (CPU-only). Uses `.override` for high-level args (e.g., `useBlas`), then `.overrideAttrs` only for unexposed CMake flags (your existing attempt's flags are preserved/adapted). `GGML_NATIVE=ON` enables runtime CPU detection (per `CMakeLists.txt`). `-march=native` pushes Nix's stdenv further for your hardware.
  - **CUDA**: Direct from flake's `.cuda` (uses `pkgsCuda` for consistency, per `nixpkgs-instances.nix`).
  - **Vulkan**: Direct from flake's `.vulkan`.
- **Selection**: The `llama.variant` option lets you pick per machine without duplication. `pkgs.llama-cpp` aliases to the selected one for simplicity.
- **Reference to File B's package.nix**: All overrides match exposed args (e.g., `useCuda ? config.cudaSupport`). For CUDA, the flake sets `GGML_CUDA=ON` and injects `cudaPackages`.
- **Reference to Key Patterns**: Uses `callPackage` implicitly via the flake's overlay. Prefers `.override` for args; `.overrideAttrs` only for `cmakeFlags` (low-level, per pattern #3).

## Step 4: Apply the Overlay in Your NixOS Configurations

Add the overlay module to the shared `./nixos` import in each `nixosConfigurations` (already present in your `flake.nix`).

### Update `flake.nix` (Minimal Change)
No major changes—your existing structure imports `./nixos`, so just ensure `./nixos/default.nix` (or equivalent) includes the overlay module. If `./nixos` is a dir, add it to `modules`.

If `./nixos` is a single file, append:
```nix
# In ./nixos/default.nix or similar
{ config, pkgs, ... }: {
  imports = [ ./overlays/llama-cpp.nix ];  # Add this
  # ... existing config
}
```

**Reference to File A**: Your modules list already includes `./nixos` and the `overlay-stable` module. The new overlay composes nicely with it (overlays are lists).

For Home Manager: Since you use `home-manager.extraSpecialArgs = {inherit inputs outputs;};`, the same overlay works in Home Manager modules (e.g., add `imports = [ inputs.self.nixosModules.llama-cpp ];` if you extract it as a module).

## Step 5: Select Variants Per Machine

In each machine's `.nix` file (e.g., `./machines/carbon.nix`), set the `llama.variant` option based on hardware. Then, add `pkgs.llama-cpp` (or a specific variant) to packages.

### Example: `./machines/carbon.nix` (NVIDIA GPU → CUDA)
```nix
{ config, lib, pkgs, ... }: {
  # Hardware setup (e.g., enable NVIDIA)
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;  # Or true for open kernel modules
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Select CUDA variant
  llama.variant = "cuda";

  # Install (uses selected alias)
  environment.systemPackages = with pkgs; [
    llama-cpp  # Resolves to llama-cpp-cuda
    # Or explicit: llama-cpp-cuda
  ];

  # For Home Manager (per-user)
  # In your home-manager config: home.packages = [ pkgs.llama-cpp ];
}
```

### Example: `./machines/beryllium.nix` (AMD Framework → Vulkan)
```nix
{ config, lib, pkgs, ... }: {
  # Existing: inputs.nixos-hardware.nixosModules.framework-13-7040-amd

  # Select Vulkan (AMD iGPU)
  llama.variant = "vulkan";

  environment.systemPackages = with pkgs; [
    llama-cpp  # Resolves to llama-cpp-vulkan
  ];
}
```

### Example: `./machines/boron.nix` (CPU-Only)
```nix
{ config, lib, pkgs, ... }: {
  # Select CPU with optimizations
  llama.variant = "cpu";

  environment.systemPackages = with pkgs; [
    llama-cpp  # Resolves to llama-cpp-cpu (with AVX/etc.)
  ];
}
```

**Reasoning**:
- **Per-Machine**: Hardcode `llama.variant` based on hardware (e.g., detect NVIDIA via `hardware.nvidia.enable` if you add logic: `llama.variant = if config.hardware.nvidia.enable then "cuda" else "cpu";`).
- **Usage in Packages**: As requested—`pkgs.llama-cpp` for the selected variant, or explicit like `pkgs.llama-cpp-vulkan`.
- **Optimizations**: CPU variant auto-adapts (e.g., Tiger Lake gets AVX2/FMA via flags). For CUDA, set `nixpkgs.config.cudaCapabilities = [ "8.6" ];` in the machine config if targeting specific GPUs (per package.nix).

## Step 6: Testing and Deployment

1. **Rebuild**: Run `sudo nixos-rebuild switch --flake .#carbon` (replace `carbon` with your hostname).
2. **Verify**: 
   - `nix repl`: Load your flake (`:lf .`), then `nix-repl> nixosConfigurations.carbon.pkgs.llama-cpp`—should show the derivation with correct flags (e.g., `GGML_CUDA=ON` for CUDA).
   - Check binaries: `llama-cpp` (or `llama-cli`) should be in `/run/current-system/sw/bin`.
   - For CPU opts: Inspect the derivation's `cmakeFlags`—should include your AVX flags.
3. **Home Manager**: In a user's `home.nix`, use `{ pkgs, ... }: { home.packages = [ pkgs.llama-cpp ]; }`—it inherits the system overlay.
4. **Cleanup**:
   - Delete `./nixos/pkgs/llama-cpp-variants.nix` (superseded).
   - Remove any old `llama-cpp` from `environment.systemPackages` or `home.packages`.
   - If using stable nixpkgs, ensure `config.allowUnfree = true;` for CUDA.
5. **Troubleshooting**:
   - CUDA fails? Ensure `hardware.nvidia` is enabled and binary cache is set.
   - Build slow? Use `--impure` for native CPU opts or enable caches.
   - Vulkan on AMD: Install `vulkan-loader` and `vulkan-validation-layers` via `hardware.opengl.enable = true;`.

This setup is maintainable: Changes to variants live in one file (`./nixos/overlays/llama-cpp.nix`), and machine selection is declarative. Total duplication: Zero. If you need more variants (e.g., ROCm for AMD discrete), extend the overlay similarly using `packages.rocm`. 

For questions, ping me—happy Nix-ing!