# 🦙 Llama‑cpp on NixOS – A Clean, Per‑Hardware Build Strategy

The goal is to replace the built‑in `llama-cpp` derivation from *nixpkgs* with the **official llama‑cpp flake** (`github:ggml-org/llama.cpp`) and, for every machine in your fleet, expose the right build variant

| Hardware | Variant to use | How to enable |
|---------|------------------|--------------|
| NVIDIA GPU | **CUDA‑accelerated** | `llama-cpp-cuda` |
| Vulkan‑capable GPU | **Vulkan‑accelerated** | `llama-cpp-vulkan` |
| CPU‑only | **CPU‑optimised** | `llama-cpp-cpu` |
| All | **Architecture‑specific optimisations** | Via the `ltmFlags` we add to the CPU package |

Below is a step‑by‑step plan that keeps the configuration modular, avoids code duplication, and follows modern Flake best practices.

> **TL;DR**  
> 1. Add the llama‑cpp flake as an input.  
> 2. Create a single *overlay* that defines the three variants.  
> 3. Add that overlay to every system configuration.  
> 4. Select the variant in the machine‑specific module.  
> 5. Remove the old `llama-cpp-variants.nix` file – the overlay is all you need.

--------------------------------------------------------------------------  

## 1. Pull in the llama‑cpp flake

Open your root `flake.nix` and add a new input.  Keep the `nixpkgs` follow‑through so the flake uses the same Nixpkgs tree you already have.

```nix
# flake.nix  (excerpt)

inputs = {
  ...
  llama-cpp = {
    url = "github:ggml-org/llama.cpp";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ...
};
```

> **Why** – The llama‑cpp repo is a proper Flake, so we can grab its outputs (`packages`, `overlays`, …) cleanly.

--------------------------------------------------------------------------  

## 2. Write a single, reusable overlay

Create **`nixos/overlays/llama-cpp.nix`** (or put the code inline in a module – we’ll show both ways).  
The overlay receives `inputs` from the `specialArgs` of the system configuration, and it returns the *real* overlay `final: prev:` that the Nixpkgs engine expects.

```nix
# nixos/overlays/llama-cpp.nix
{ inputs, lib, ... }:

final: prev: let
  # Grab the per‑system package set from the llama‑cpp flake.
  llamaPkgs = inputs.llama-cpp.packages.${prev.system};

in
{
  # 1️⃣  Default (CPU‑only) – just expose it for compatibility.
  llama-cpp = prev.llama-cpp;          # from the llama‑cpp overlay

  # 2️⃣  A CPU‑optimised variant.
  # We keep the default (native) but explicitly enable all useful CPU flags.
  llama-cpp-cpu = prev.llama-cpp.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ lib.optionals prev.stdenv.isLinux [
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
    # preserve the native optimizer flag in case Nixpkgs disables it
    buildFlags = old.buildFlags or [ ] ++ [ "-DGGML_NATIVE=ON" ];
  });

  # 3️⃣  GPU variants – just alias the specialised packages bundled
  #      by the official flake.  No need to re‑override anything.
  llama-cpp-vulkan = llamaPkgs.vulkan;
  llama-cpp-cuda   = llamaPkgs.cuda;

  # Optional: keep an alias to make it obvious that `llama-cpp` is the
  # unmodified default (CPU only, native optimisations if you prefer).
  default = llama-cpp;
}
```

### Why this overlay works

| Feature | Reference from the provided files |
|---------|------------------------------------|
| *Access to input flake* | `inputs.llama-cpp` – declared in root `flake.nix` |
| *Per‑system filtering* | `${prev.system}` → `inputs.llama-cpp.packages.${prev.system}` |
| *Override CPU flags* | `.overrideAttrs { cmakeFlags = ... }` – `package.nix` exposes `cmakeFlags` |
| *GPU builds* | `llamaPkgs.vulkan / cuda` are already built by the llama‑cpp flake using its own `pkgsCuda` instance (`.devops/nix/nixpkgs-instances.nix`) |
| *Clean, single source of truth* | No duplicated logic, default behavior preserved |

--------------------------------------------------------------------------  

## 3. Hook the overlay into every system

### Option A – Inline the overlay

In each `nixosConfigurations.{machine}` entry (the same we already have in `flake.nix`), add the overlay to the `nixpkgs.overlays` list **before** the rest of your modules.  
The overlay uses the `specialArgs` you already propagate.

```nix
# flake.nix – snippet inside each nixosConfiguration
modules = [
  # ①  Make the overlay available
  {
    nixpkgs.overlays =
      [  inputs.llama-cpp.overlays.default  # gives you `llama-cpp`
         (inputs.nixos-pkgs?.)/overlays/llama-cpp.nix ];   # your custom overlay
  }

  # ... the rest of your modules
  ./machines/${machine}.nix
  ./nixos
  inputs.home-manager.nixosModules.home-manager
  ...
];
```

### Option B – A shared module

Create a small module that adds all the overlays and reuse it in every configuration:

```nix
# nixos/common/overlays-module.nix
{ inputs, pkgs, ... }:
{
  nixpkgs.overlays = [
    inputs.llama-cpp.overlays.default
    (inputs.nixos-pkgs/.../overlays/llama-cpp.nix)
  ];
}
```

And import it once per machine:

```nix
modules = [
  ./nixos/common/overlays-module.nix
  ./machines/${machine}.nix
  ... 
];
```

Either approach guarantees that `pkgs.llama-cpp-cpu`, `pkgs.llama-cpp-cuda`, and `pkgs.llama-cpp-vulkan` are available everywhere.

--------------------------------------------------------------------------  

## 4. Pick a variant per machine

Now the machine configs are as simple as listing the desired package.

### Example – CPU‑only machine (`carbon`)

```nix
# machines/carbon.nix
{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-cpu   # <── the CPU‑optimised variant
    # … other packages
  ];
}
```

### Example – CUDA machine (`beryllium`)

```nix
# machines/beryllium.nix
{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-cuda   # <── the CUDA‑accelerated variant
    # … other packages
  ];
}
```

### Example – Vulkan machine (`boron`)

```nix
# machines/boron.nix
{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-vulkan   # <── the Vulkan‑accelerated variant
  ];
}
```

### Home Manager usage

If you prefer to set it in a Home Manager profile, it is identical:

```nix
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    pkgs.llama-cpp-cuda   # or any other variant
  ];
}
```

--------------------------------------------------------------------------  

## 5. Clean‑up

* Delete or rename the obsolete file `nixos/pkgs/llama-cpp-variants.nix`.  
  Your new overlay does the same job, but it is the **single point of truth**.  
* You can keep the old file as a reference file (e.g., `docs/llama-cpp-variants-reference.nix`) – but it should **not** be used by any module.  
* Optionally bump the `llama-cpp` flake input to a specific commit or tag if reproducibility matters:  

  ```nix
  llama-cpp = {
    url = "github:ggml-org/llama.cpp/0.1.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```

--------------------------------------------------------------------------  

## 6. Recap – How everything fits together

| Step | What we did | Where the code lives |
|------|-------------|----------------------|
| 1️⃣ | Added the llama‑cpp flake as an input | `flake.nix` |
| 2️⃣ | Wrote `nixos/overlays/llama-cpp.nix` that exports three variants | `nixos/overlays/llama-cpp.nix` |
| 3️⃣ | Hooked the overlay into every `nixosConfiguration` | `flake.nix` (modules list) |
| 4️⃣ | Picked a variant per machine | `machines/*.nix` or `home/*.nix` |
| 5️⃣ | Removed the old custom overlay file | deleted `nixos/pkgs/llama-cpp-variants.nix` |

Now your fleet can build:

* A **CPU‑only, highly‑optimised** runtime on all devices.  
* A **CUDA** build whenever a qualified NVIDIA GPU exists.  
* A **Vulkan** build whenever you only have a Vulkan‑capable GPU.  

All with a single, minimalistic overlay, zero code duplication, and fully type‑safe per‑system overrides. Happy LLaMA-ing! 🚀