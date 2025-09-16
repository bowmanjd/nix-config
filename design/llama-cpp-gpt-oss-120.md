# 📚 How to replace the `llama-cpp` package from **nixpkgs** with the official `llama.cpp` flake  
*(and get a per‑machine CUDA / Vulkan / CPU‑optimised build)*  

Below is a **complete, step‑by‑step guide** that works with the files you already have.  
It follows modern Nix‑OS/Flake best‑practices, keeps everything modular, and removes the old, broken overlay (`./nixos/pkgs/llama-cpp-variants.nix`).

---

## 1. Overview of the required changes

| What we do | Why (and where the information comes from) |
|------------|--------------------------------------------|
| **Add `llama.cpp` as a flake input** | `flake.nix` (File A) already passes `inputs` to all modules via `specialArgs`. Adding a new input is the canonical way to make the external flake visible. |
| **Expose the three variants (CPU, CUDA, Vulkan) as separate packages** | The official flake already builds `default`, `cuda` and `vulkan` (see **File B** – `outputs.perSystem.packages`). We only need a thin overlay that re‑exports them under nice names (`llama-cpp‑cpu`, …) and adds the extra CPU‑optimisation flags you tried in **File C**. |
| **Add the overlay to the Nixpkgs evaluation used by every host** | `nixpkgs.overlays` is already set in each machine module (File A). We just extend the list with our new overlay. |
| **Select the correct variant per host** | Either (a) define a small boolean in the host’s `machine/*.nix` file and use a conditional in `environment.systemPackages`, or (b) let a top‑level attribute map host‑name → package. Both are idiomatic. |
| **Clean up** | Remove the old hand‑rolled overlay (`./nixos/pkgs/llama-cpp-variants.nix`). The new overlay completely replaces it. |

---

## 2. Add the official `llama.cpp` flake as an input

Edit **File A** (`flake.nix`) – add a new entry in the `inputs` set:

```nix
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # … (other inputs you already have) …

    # ← NEW: llama.cpp
    llama-cpp = {
      url = "github:ggml-org/llama.cpp";
      # make it follow the same nixpkgs you already use, otherwise you get a
      # second copy of nixpkgs for the flake’s own overlays.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
```

*Why*: The flake’s `outputs` contain an overlay (`llama-cpp.overlays.default`) and ready‑made packages (`default`, `cuda`, `vulkan`). By pulling the flake as an input we can reuse both.

---

## 3. Create a **tiny, dedicated overlay** that re‑exports the three variants and adds the CPU‑optimisation flags you want

Create a new file, e.g. `overlays/llama-cpp.nix` (feel free to place it wherever you keep other overlays).

```nix
# overlays/llama-cpp.nix
#
# 1️⃣ Re‑export the three variants that the upstream flake already builds:
#    * default → pure‑CPU (no GPU)
#    * cuda    → CUDA‑accelerated
#    * vulkan  → Vulkan‑accelerated
#
# 2️⃣ Provide a *CPU‑optimised* variant that turns on the instruction‑set
#    flags you listed in your previous overlay (File C).

{ inputs, system }:

let
  # Pull the per‑system package set from the llama.cpp flake
  llamaPkgs = inputs.llama-cpp.packages.${system};

  # Base CPU package (no GPU).  We keep it as `llama-cpp-cpu-base` for
  # readability; the final name we expose will be `llama-cpp-cpu`.
  llamaCpuBase = llamaPkgs.default;

  # Apply the extra CMake flags that you tried in File C.
  # We use `.overrideAttrs` only because the upstream derivation does **not**
  # expose those flags as top‑level arguments.
  llamaCpuOptimised = llamaCpuBase.overrideAttrs (old: {
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

in
{
  # The overlay entry – it will be added to `nixpkgs.overlays`.
  # `final` is the pkgs set that already contains the overlay‑chain,
  # `prev` is the set *without* our overlay.
  overlays = final: prev: {
    # Keep the original llama‑cpp name for people who expect it.
    llama-cpp = llamaPkgs.default;      # plain CPU (no extra flags)

    # Public names we will use in the system / home‑manager modules:
    llama-cpp-cpu    = llamaCpuOptimised;   # your tuned CPU build
    llama-cpp-cuda   = llamaPkgs.cuda;      # CUDA variant
    llama-cpp-vulkan = llamaPkgs.vulkan;    # Vulkan variant
  };
}
```

### What this does

* **No duplicate builds** – we reuse the packages the upstream flake already builds (`default`, `cuda`, `vulkan`).  
* **CPU optimisation** – we only add the extra `cmakeFlags` once, via `overrideAttrs`.  
* **Clear names** – `llama-cpp-cpu`, `llama-cpp-cuda`, `llama-cpp-vulkan`. You can still refer to `llama-cpp` if you need the vanilla CPU version.

---

## 4. Wire the new overlay into every NixOS configuration

You have two ways:

* **A. Add it directly in each host’s module list** – this is the smallest change.
* **B. Put it into a shared module** (e.g. `./nixos/overlays.nix`) – keeps the host files cleaner.

Both approaches are shown; pick the one you like.

### 4.A. Directly in each host (quick start)

Edit each host entry in **File A** (`flake.nix`). In the `modules = [ … ]` list, after the existing block that adds `overlay-stable`, add the new overlay:

```nix
          ({
            config,
            pkgs,
            ...
          }: {
            nixpkgs.overlays = [
              overlay-stable
              # ← NEW: llama‑cpp overlay (we pass `inputs` and `system` explicitly)
              (import ./overlays/llama-cpp.nix {
                inherit inputs;
                system = "x86_64-linux";   # or aarch64-linux for the ARM hosts
              })
            ];
          })
```

Do the same for every host (`carbon`, `beryllium`, `boron`, `nitrogen`).  

*Why the `system` argument?*  
The overlay we wrote expects the system architecture to pick the correct `llama-cpp` sub‑package (`${system}`).

### 4.B. Centralised overlay module (recommended for many hosts)

Create a tiny module `./nixos/llama-cpp-overlay.nix`:

```nix
# ./nixos/llama-cpp-overlay.nix
{ inputs, ... }:

{
  nixpkgs.overlays = [
    (import ./../overlays/llama-cpp.nix {
      inherit inputs;
      system = builtins.currentSystem;   # works because the module is evaluated in the same system
    })
  ];
}
```

Then, in **File A**, replace the per‑host overlay block with a reference to the shared module:

```nix
          inputs.home-manager.nixosModules.home-manager
          ./nixos/llama-cpp-overlay.nix   # ← NEW
          inputs.nixos-hardware.nixosModules.framework-13-7040-amd
```

Now every host automatically gets the overlay, and you only have to maintain a single line.

---

## 5. Selecting the right variant per machine

### 5.1. Decide on a simple “GPU‑type” attribute

Add a small option to each machine’s config file (`machines/*.nix`). For example, in `machines/carbon.nix` (the machine that has an NVIDIA GPU) you could add:

```nix
{ lib, ... }:
{
  # a custom attribute inside `hardware` (you could pick any namespace)
  hardware.gpu = lib.mkDefault "cuda";   # possible values: "cuda", "vulkan", "cpu"
}
```

For a Vulkan‑only laptop (`beryllium.nix`):

```nix
{ lib, ... }:
{
  hardware.gpu = lib.mkDefault "vulkan";
}
```

And for a pure‑CPU workstation (`boron.nix`):

```nix
{ lib, ... }:
{
  hardware.gpu = lib.mkDefault "cpu";
}
```

### 5.2. Use that flag in the system package list

Add the following to **every** host (or put it into a shared module if you prefer) – it picks the right package from `pkgs` based on the attribute we just set:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  gpuKind = config.hardware.gpu or "cpu";   # fallback safe
  llamaPkg = builtins.attrNames {
    cpu    = pkgs.llama-cpp-cpu;
    cuda   = pkgs.llama-cpp-cuda;
    vulkan = pkgs.llama-cpp-vulkan;
  }.${gpuKind};
in
{
  environment.systemPackages = with pkgs; [
    llamaPkg
    # other packages …
  ];
}
```

**Explanation**  
* `gpuKind` reads the custom attribute you set in the host file.  
* `builtins.attrNames` is a tiny trick to map `"cpu"` → `pkgs.llama-cpp-cpu`, etc., without an `if` chain.  

If you use **Home Manager** instead of system packages, the same expression works inside `home.packages`:

```nix
home.packages = with pkgs; [
  llamaPkg
];
```

### 5.3. Optional: central mapping in the flake outputs

If you prefer to keep host‑specific logic *outside* the NixOS modules, you can expose a map from hostname → package in `flake.nix`:

```nix
outputs = { self, inputs, ... }@inputs: let
  # … (your existing let‑bindings)
  mkLlamaPkg = system: gpuKind:
    let pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ overlay-stable (import ./overlays/llama-cpp.nix { inherit inputs system; }) ];
        };
    in
    pkgs."llama-cpp-${gpuKind}";
in {
  # expose a convenience attribute:
  hostLlamaPkg = {
    carbon    = mkLlamaPkg "x86_64-linux" "cuda";
    beryllium = mkLlamaPkg "x86_64-linux" "vulkan";
    boron     = mkLlamaPkg "x86_64-linux" "cpu";
    nitrogen  = mkLlamaPkg "x86_64-linux" "cpu";
  };
  # … rest of your outputs
}
```

Then inside a host module you can simply write:

```nix
environment.systemPackages = [ inputs.self.hostLlamaPkg.${config.networking.hostName} ];
```

Both approaches are idiomatic; pick whichever keeps your repo clearer.

---

## 6. Home Manager usage (if you prefer user‑level packages)

Add the same overlay to the Home Manager `pkgs` set by enabling `useGlobalPkgs = true` (which you already do) and then reference the package in `home.packages`:

```nix
{
  # inside your home-manager module
  home.packages = with pkgs; [
    # The same conditional trick can be used here, or you can hard‑code
    # the variant you always want for a given user.
    llama-cpp-cpu
  ];
}
```

If you want the per‑host variant, you can read the host attribute via `builtins.getEnv "HOSTNAME"` (set by the system) or expose it via `specialArgs` – but the system‑level approach from §5 already guarantees the correct binary is installed system‑wide, which most users prefer.

---

## 7. Clean‑up: remove the old, broken overlay

Delete the file you created earlier:

```bash
rm ./nixos/pkgs/llama-cpp-variants.nix
```

Also remove any references to `inputs.llama-cpp` or `llama-cpp.packages` that might still be lingering in your personal overlays – they are no longer needed.

---

## 8. Full, minimal **final `flake.nix`** (showing the relevant parts only)

Below is a **condensed** version of your original `flake.nix` with the new input, the overlay wiring, and the per‑host GPU flag handling. You can copy‑paste it and only adjust the parts that differ for your own repo (e.g., other inputs).

```nix
{
  description = "techyporcupine's NixOS Config!";

  inputs = {
    # ── Existing ─────────────────────────────────────
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    waybar = {
      url = "github:Alexays/Waybar/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "