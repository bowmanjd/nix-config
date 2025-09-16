# Integrating Optimized llama.cpp Builds Into Your NixOS Fleet (Flakes)

This document is a step-by-step implementation plan to replace the `llama-cpp` package from `nixpkgs` with variants built directly from the official upstream flake (`github:ggml-org/llama.cpp`), with per‑machine hardware optimization (CPU, CUDA, Vulkan, etc.).  
It references your existing configuration (File A) and the upstream llama.cpp Nix logic (Files B1–B5), and replaces your previous overlay attempt (File C) with a cleaner, idiomatic design.

---

## Table of Contents

1. Design Goals  
2. Why Use the Upstream Flake Instead of Re‑Packaging  
3. Overview of the Upstream Flake (File B)  
4. Strategy Summary  
5. Step 1: Add llama.cpp as a Flake Input  
6. Step 2: Create a Dedicated Overlay for Variant Exposure  
7. Step 3: Register the Overlay in All NixOS Configurations  
8. Step 4: Selecting Variants Per Machine  
9. Step 5: Using Packages in Home Manager  
10. Step 6: (Optional) Extra CPU Optimization Strategy  
11. Step 7: (Optional) Adding a ROCm Variant  
12. Step 8: Cleanup (Remove Old Overlay)  
13. Full Code Snippets Recap  
14. Trade-offs and Notes  
15. Future Extensions  

---

## 1. Design Goals

- Consume llama.cpp directly from upstream (File B’s flake) instead of `nixpkgs`.
- Provide distinct, discoverable package names:
  - llama-cpp (baseline upstream default)
  - llama-cpp-cpu (CPU-native optimized)
  - llama-cpp-vulkan (+ optional native)
  - llama-cpp-cuda (+ optional native)
- Keep configuration DRY and idiomatic (avoid copy/paste derivations).
- Use overlays (preferred pattern for injecting packages into `pkgs`, cf. upstream's overlay mechanism in File B1).
- Allow simple selection per machine (e.g. `environment.systemPackages = [ pkgs.llama-cpp-cuda ];`).
- Respect upstream’s `override` vs `overrideAttrs` layering: use `.override` only when toggling llama.cpp’s exposed arguments (`useVulkan`, etc.), and use `.overrideAttrs` only when forcing custom CMake flags (e.g. enabling `GGML_NATIVE`).

---

## 2. Why Use the Upstream Flake Instead of Re‑Packaging

From File B1 (`flake.nix`) and File B2 (`scope.nix`), upstream already provides:
- A maintained overlay (`overlays.default`) that injects `llama-cpp` as `pkgs.llama-cpp`.
- A matrix of variants via `packages.${system}` (default, cuda, vulkan, rocm).
- Specialized `pkgsCuda` and `pkgsRocm` instantiations (File B4) to ensure dependency graph coherency (critical for CUDA builds).

Re‑implementing this would duplicate logic and risk divergence. Instead, we consume it and layer minimal overrides.

---

## 3. Overview of the Upstream Flake (File B Highlights)

- File B1 defines `packages`:
  - `default` (CPU baseline, conservative flags; sets `GGML_NATIVE=OFF` via Nix derivation in File B3).
  - `cuda`, `vulkan`, `rocm`, etc.
- File B3 (`package.nix`) accepts booleans like `useVulkan`, `useCuda`, `useRocm`. These are the correct knobs for GPU backend enabling.
- CPU specialization defaults are intentionally disabled (`GGML_NATIVE` OFF) because Nix sets `SOURCE_DATE_EPOCH`, making builds non‑machine‑specific by default. You explicitly want the opposite—per-system CPU optimization—so we override that.
- Upstream overlay (File B1) exposes `llama-cpp` (default) as `pkgs.llama-cpp`.

---

## 4. Strategy Summary

1. Add `llama-cpp` flake input with `inputs.nixpkgs.follows = "nixpkgs"` to avoid redundant eval.
2. Add upstream overlay (`inputs.llama-cpp.overlays.default`) to your system overlays.
3. Add your own overlay that:
   - Re-exports upstream default as `llama-cpp`.
   - Creates custom variants (cpu, vulkan, cuda) with optional native optimization.
4. Replace old file `./nixos/pkgs/llama-cpp-variants.nix` (File C) with a cleaner new file (e.g. `./overlays/llama-cpp.nix`).
5. Use per‑machine selection inside each `machines/<host>.nix`.
6. (Optional) Extend with ROCm or dynamic host detection later.

---

## 5. Step 1: Add llama.cpp as a Flake Input

Modify File A (`flake.nix`) inputs section:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

  nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  waybar = {
    url = "github:Alexays/Waybar/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # NEW: upstream llama.cpp flake
  llama-cpp = {
    url = "github:ggml-org/llama.cpp";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

---

## 6. Step 2: Create a Dedicated Overlay for Variant Exposure

Create a new file (recommended path): `./overlays/llama-cpp.nix`

```nix
# overlays/llama-cpp.nix
# Custom overlay wrapping upstream llama.cpp flake variants.
# Provides optimized and GPU-specific variants under friendly names.

{ inputs }:
final: prev:

let
  system = prev.system;
  upstream = inputs.llama-cpp;                    # The upstream flake
  upstreamPkgs = upstream.packages.${system};     # Access flake output packages
  # Upstream overlay already injects `prev.llama-cpp` as the default baseline
  base = prev.llama-cpp;
in {
  # Explicitly re-expose upstream baseline (optional clarity)
  llama-cpp = base;

  # CPU-native optimized (forces GGML_NATIVE ON).
  llama-cpp-cpu =
    base.overrideAttrs (old: {
      pname = "${old.pname}-native";
      cmakeFlags = old.cmakeFlags ++ [
        "-DGGML_NATIVE=ON"
        # Keep individual flags OFF unless you know your deployment CPUs all support them;
        # GGML_NATIVE does auto-detection and injects the right -m* flags.
        # If you want to force specific features, you could append:
        # "-DGGML_AVX2=ON" "-DGGML_FMA=ON" ...
      ];
    });

  # Vulkan variant.
  llama-cpp-vulkan = base.override { useVulkan = true; };

  # Vulkan + native CPU tuning
  llama-cpp-vulkan-native =
    (base.override { useVulkan = true; }).overrideAttrs (old: {
      pname = "${old.pname}-vulkan-native";
      cmakeFlags = old.cmakeFlags ++ [ "-DGGML_NATIVE=ON" ];
    });

  # CUDA variant (from upstream's preconfigured pkgsCuda derivation)
  llama-cpp-cuda = upstreamPkgs.cuda;

  # CUDA + native CPU tuning
  llama-cpp-cuda-native =
    upstreamPkgs.cuda.overrideAttrs (old: {
      pname = "${old.pname}-native";
      cmakeFlags = old.cmakeFlags ++ [ "-DGGML_NATIVE=ON" ];
    });

  # (Optional) You can add ROCm similarly later:
  # llama-cpp-rocm = upstreamPkgs.rocm;
  # llama-cpp-rocm-native = upstreamPkgs.rocm.overrideAttrs (old: { ... });
}
```

---

## 7. Step 3: Register the Overlay in All NixOS Configurations

Right now, in File A each `nixosSystem` duplicates:

```nix
nixpkgs.overlays = [ overlay-stable ];
```

Modify that snippet to include both the upstream llama overlay and your wrapper overlay.  
For each machine entry in `flake.nix`, change:

```nix
modules = [
  ({ config, pkgs, ... }: {
    nixpkgs.overlays = [
      overlay-stable
      inputs.llama-cpp.overlays.default
      (import ./overlays/llama-cpp.nix { inherit inputs; })
    ];
  })
  # ...
];
```

(If you prefer DRY: factor this mini-module into its own file, e.g. `./modules/overlays.nix`, and reuse.)

---

## 8. Step 4: Selecting Variants Per Machine

In `./machines/<hostname>.nix`, choose the appropriate package(s). Examples:

CPU-only host (no GPU):

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.llama-cpp-cpu
  ];
}
```

NVIDIA GPU host:

```nix
{ pkgs, ... }:
{
  # Make sure you already have your NVIDIA driver / CUDA runtime configured
  # (e.g. hardware.nvidia.*, services.xserver.videoDrivers = [ "nvidia" ]).
  environment.systemPackages = [
    pkgs.llama-cpp-cuda
  ];
}
```

Vulkan-capable (vendor-agnostic fallback path):

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.llama-cpp-vulkan
  ];
}
```

If you want the native CPU tuning variant with GPU backend:

```nix
environment.systemPackages = [ pkgs.llama-cpp-cuda-native ];
# or
environment.systemPackages = [ pkgs.llama-cpp-vulkan-native ];
```

---

## 9. Step 5: Using Packages in Home Manager

Because you already have:

```nix
home-manager.useGlobalPkgs = true;
home-manager.useUserPackages = true;
```

Home Manager will see the same `pkgs` (with overlays applied).  
In a Home Manager module:

```nix
{ pkgs, ... }:
{
  home.packages = [
    pkgs.llama-cpp-cpu
  ];
}
```

No extra wiring is needed because `specialArgs = { inherit inputs outputs; }` (File A) already propagates `inputs` if you later need them.

---

## 10. Step 6: (Optional) Extra CPU Optimization Strategy

Enabling `GGML_NATIVE` makes the build sensitive to the build machine's CPU features. Important considerations:

- If you use remote builders with a different microarchitecture, you might emit binaries that crash locally (Illegal instruction).  
- To guarantee correctness:
  - Build locally (`nix build` or `nh os switch` without remote builders), or
  - Maintain per-host caches keyed by CPU flags (complex), or
  - Skip `GGML_NATIVE` and explicitly enable only safe instruction sets you know are present.
  
If you want to explicitly force a Tiger Lake set (as hinted in File C), you could replace the native override with:

```nix
.overrideAttrs (old: {
  pname = "${old.pname}-tigerlake";
  cmakeFlags = old.cmakeFlags ++ [
    "-DGGML_NATIVE=OFF"
    "-DGGML_SSE42=ON"
    "-DGGML_AVX=ON"
    "-DGGML_F16C=ON"
    "-DGGML_AVX2=ON"
    "-DGGML_BMI2=ON"
    "-DGGML_FMA=ON"
    # Avoid AVX512 unless you are on a CPU that supports it (Tiger Lake does not)
  ];
})
```

This is safer across remote builders, but less “auto”.

---

## 11. Step 7: (Optional) Adding a ROCm Variant

If you later have an AMD GPU with ROCm support:

```nix
  llama-cpp-rocm = upstreamPkgs.rocm;
  llama-cpp-rocm-native =
    upstreamPkgs.rocm.overrideAttrs (old: {
      pname = "${old.pname}-native";
      cmakeFlags = old.cmakeFlags ++ [ "-DGGML_NATIVE=ON" ];
    });
```

Then select `pkgs.llama-cpp-rocm` per host.

---

## 12. Step 8: Cleanup (Remove Old Overlay File)

Delete the obsolete file (File C):

```
rm ./nixos/pkgs/llama-cpp-variants.nix
```

And remove any references to it if they existed (none remain after adopting the new overlay).

---

## 13. Full Code Snippets Recap

A. flake.nix (inputs section excerpt):

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
  nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  waybar = {
    url = "github:Alexays/Waybar/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  llama-cpp = {
    url = "github:ggml-org/llama.cpp";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

B. Overlay file (`overlays/llama-cpp.nix`):

```nix
{ inputs }:
final: prev:
let
  system = prev.system;
  upstream = inputs.llama-cpp;
  upstreamPkgs = upstream.packages.${system};
  base = prev.llama-cpp;
in {
  llama-cpp = base;

  llama-cpp-cpu = base.overrideAttrs (old: {
    pname = "${old.pname}-native";
    cmakeFlags = old.cmakeFlags ++ [ "-DGGML_NATIVE=ON" ];
  });

  llama-cpp-vulkan = base.override { useVulkan = true; };

  llama-cpp-vulkan-native =
    (base.override { useVulkan = true; }).overrideAttrs (old: {
      pname = "${old.pname}-vulkan-native";
      cmakeFlags = old.cmakeFlags ++ [ "-DGGML_NATIVE=ON" ];
    });

  llama-cpp-cuda = upstreamPkgs.cuda;

  llama-cpp-cuda-native =
    upstreamPkgs.cuda.overrideAttrs (old: {
      pname = "${old.pname}-native";
      cmakeFlags = old.cmakeFlags ++ [ "-DGGML_NATIVE=ON" ];
    });
}
```

C. Add overlays in each machine block inside `flake.nix`:

```nix
modules = [
  ({ ... }: {
    nixpkgs.overlays = [
      overlay-stable
      inputs.llama-cpp.overlays.default
      (import ./overlays/llama-cpp.nix { inherit inputs; })
    ];
  })
  ./machines/carbon.nix
  ./nixos
  inputs.home-manager.nixosModules.home-manager
  # etc...
];
```

D. Machine package selection (e.g. `machines/beryllium.nix`):

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.llama-cpp-cuda  # or any variant
  ];
}
```

E. Home Manager example:

```nix
{ pkgs, ... }:
{
  home.packages = [
    pkgs.llama-cpp-vulkan-native
  ];
}
```

---

## 14. Trade-offs and Notes

- Reproducibility vs Performance: Enabling `GGML_NATIVE` trades deterministic, generic binaries for per-host performance. This is a deliberate choice given your stated goal.
- Remote Builders: Avoid `GGML_NATIVE` if using heterogeneous build farms.
- Flag Explosion: Manually forcing every `-DGGML_*` feature (like in File C) risks enabling instruction sets unsupported by some hardware. Prefer `GGML_NATIVE=ON` or a curated subset.
- Backend Choice Priority: If you enable both Vulkan and CUDA in one build (not typical here), you must manage runtime selection—keeping distinct derivations avoids complexity.
- Overlay Order: Ensure `inputs.llama-cpp.overlays.default` comes before your custom overlay so `prev.llama-cpp` exists at the time your overlay runs.

---

## 15. Future Extensions

Possible refinements:

1. Add a module option:
   - `services.llama-cpp.package = pkgs.llama-cpp-cuda;`
   - Provide systemd service to run `llama-server`.
2. Add ROCm variants (already shown).
3. Introduce host detection:
   - A per-host attr mapping in `flake.nix` to automatically select variant based on a metadata file (e.g. `./machines/meta/<host>.nix`).
4. Pin llama.cpp revision explicitly by using `flake.lock` updates and commit review.
5. Provide a binary cache for heavy CUDA builds to avoid rebuild avalanche.

---

## Final Checklist

- [x] Add upstream llama.cpp flake input.
- [x] Add upstream overlay.
- [x] Implement custom variant overlay.
- [x] Remove old `llama-cpp-variants.nix` (File C).
- [x] Select variant per machine.
- [x] (Optional) Enable native CPU tuning responsibly.

---

If you’d like, I can next help you add a systemd service for running `llama-server` with a specific model, or implement automatic variant selection logic. Just ask.

Happy hacking!