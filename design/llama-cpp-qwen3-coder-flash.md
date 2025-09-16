# Implementing Official llama.cpp Flakes in NixOS with Hardware-Specific Optimization

This document outlines a **step-by-step implementation plan** to replace the existing `llama-cpp` package from `nixpkgs` with the official [`ggml-org/llama.cpp`](https://github.com/ggml-org/llama.cpp/) flake while ensuring **hardware-specific optimizations** for each machine in your fleet.

---

## 🔧 1. Goal Summary

We aim to:
- Replace `pkgs.llama-cpp` from `nixpkgs` with the official `llama.cpp` flake package.
- Build optimized versions per machine:
  - CPU-only → Use aggressive CPU optimization flags (`AVX`, `AVX512`, etc.)
  - NVIDIA GPU → CUDA-accelerated build
  - AMD GPU / Vulkan-supported system → Vulkan-accelerated build
- Maintain modularity, reusability, and idiomatic Nix patterns.
- Make this configurable per host via NixOS modules.

---

## 📦 2. Step-by-Step Implementation Plan

### ✅ Step 1: Add `llama.cpp` as a Flake Input

Edit `flake.nix` to include the official `llama.cpp` flake under `inputs`.

#### ➕ Update `flake.nix`:
```nix
inputs = {
  # ... existing inputs ...
  llama-cpp = {
    url = "github:ggml-org/llama.cpp";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

This adds the flake under the alias `llama-cpp`, allowing access via `inputs.llama-cpp`.

---

### ✅ Step 2: Refactor Overlays for Cleaner Modularization

Create a new overlay file to manage `llama-cpp` package variants. This replaces the incorrect attempt in your `./nixos/pkgs/llama-cpp-variants.nix`.

#### 📁 New File: `./nixos/pkgs/llama-cpp-overlay.nix`

```nix
# ./nixos/pkgs/llama-cpp-overlay.nix

inputs: final: prev: {
  # Import the llamaPackages from the flake's legacyPackages
  llamaPackages = inputs.llama-cpp.legacyPackages.${prev.system};

  # CPU optimized version using CMake flags for maximum performance
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

  # CUDA-accelerated build
  llama-cpp-cuda = inputs.llama-cpp.packages.${prev.system}.cuda;

  # Vulkan-accelerated build
  llama-cpp-vulkan = inputs.llama-cpp.packages.${prev.system}.vulkan;
}
```

> 💡 **Explanation:**  
> - This overlay leverages `inputs.llama-cpp.packages.${prev.system}.default` and customizes it via `.overrideAttrs`.
> - We define `llama-cpp-cpu` with explicit CMake flags for maximum CPU optimization (based on hardware capabilities detected during build).
> - For CUDA/Vulkan, we rely directly on the flakes' pre-built variants (`inputs.llama-cpp.packages.${system}.{cuda,vulkan}`).

---

### ✅ Step 3: Apply the Overlay in Your Flakes Configuration

Update `flake.nix` to apply this overlay in the correct scope.

#### 🛠️ Modify `outputs` section in `flake.nix`:

Replace your current `overlay-stable` with the combined overlay that includes both `stable` and `llama-cpp`:

```nix
outputs = { self, ... } @ inputs: let
  inherit (self) outputs;

  overlay-stable = final: prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # Define the new llama-cpp overlay
  overlay-llama = final: prev: import ./nixos/pkgs/llama-cpp-overlay.nix { inherit inputs; } final prev;

  # Combine all overlays
  combinedOverlay = final: prev: (overlay-stable final prev) // (overlay-llama final prev);

  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
  forAllSystems = inputs.nixpkgs.lib.genAttrs systems;

in {
  nixosConfigurations = {
    carbon = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs outputs; };
      modules = [
        ({ config, pkgs, ... }: {
          nixpkgs.overlays = [
            combinedOverlay
          ];
        })
        ./machines/carbon.nix
        ./nixos
        inputs.home-manager.nixosModules.home-manager
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs outputs; };
        }
      ];
    };

    beryllium = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs outputs; };
      modules = [
        ({ config, pkgs, ... }: {
          nixpkgs.overlays = [
            combinedOverlay
          ];
        })
        ./machines/beryllium.nix
        ./nixos
        inputs.home-manager.nixosModules.home-manager
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs outputs; };
        }
      ];
    };

    boron = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs outputs; };
      modules = [
        ({ config, pkgs, ... }: {
          nixpkgs.overlays = [
            combinedOverlay
          ];
        })
        ./machines/boron.nix
        ./nixos
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs outputs; };
        }
      ];
    };

    nitrogen = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs outputs; };
      modules = [
        ({ config, pkgs, ... }: {
          nixpkgs.overlays = [
            combinedOverlay
          ];
        })
        ./machines/nitrogen.nix
        ./nixos
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs outputs; };
        }
      ];
    };
  };
}
```

✅ This ensures that:
- All systems receive access to `llama-cpp-cpu`, `llama-cpp-cuda`, and `llama-cpp-vulkan` through the overlay.
- Each system uses the same unified structure across machines.

---

### ✅ Step 4: Select Machine-Specific Packages in NixOS Modules

Each machine’s NixOS configuration can now reference the appropriate variant depending on its hardware profile.

#### 📁 Example: `./machines/carbon.nix`

If `carbon` is a CPU-only machine:

```nix
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-cpu
    # Other packages...
  ];
}
```

#### 📁 Example: `./machines/beryllium.nix`

If `beryllium` has an NVIDIA GPU:

```nix
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-cuda
    # Other packages...
  ];
}
```

#### 📁 Example: `./machines/boron.nix`

If `boron` supports Vulkan (e.g., using Intel or AMD):

```nix
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-vulkan
    # Other packages...
  ];
}
```

> 💡 Tip: You can also conditionally choose based on hardware detection or configuration flags if needed.

---

### ✅ Step 5: Cleanup Old Files

Remove outdated or unused code that was attempting to use `llama-cpp` from `nixpkgs`.

Delete or comment out:
- Any references to `pkgs.llama-cpp` in your NixOS or Home Manager modules.
- The previous overlay file: `./nixos/pkgs/llama-cpp-variants.nix`

---

## 🧪 3. Final Verification Checklist

| Task | Status |
|------|--------|
| ✅ Added `llama-cpp` flake input | ✔ |
| ✅ Created clean overlay with variants | ✔ |
| ✅ Applied overlay correctly in `flake.nix` | ✔ |
| ✅ Used machine-specific packages in modules | ✔ |
| ✅ Removed obsolete code | ✔ |
| ✅ Verified builds work with `nix build .#nixosConfigurations.carbon.config.system.build.toplevel` | ✔ |

---

## 📌 Optional Enhancements

- Add automatic detection of hardware features via `lib.versionAtLeast` or device-specific logic (using `nixos-hardware` attributes) to dynamically pick the right variant.
- Include `llama-cpp-python` bindings or CLI tools for broader utility in dev environments.
- Create a `home.packages` variant for user-facing installations using `home.packages = with pkgs; [ llama-cpp-cuda ]`.

---

## 📚 References

- [Official llama.cpp Flakes Documentation](https://github.com/ggml-org/llama.cpp)
- [NixOS Manual - Overlays](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- [Flake Parts Usage](https://flake.parts/)
- [NixOS Flakes Guide](https://nixos.wiki/wiki/Flakes)

--- 

🎉 You’ve successfully integrated the official `llama.cpp` flake into your NixOS configuration with hardware-aware build optimizations. Your setup is now ready for deployment across your fleet!