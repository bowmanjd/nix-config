# Action Plan: Replacing nixpkgs `llama-cpp` with the official `llama.cpp` flake  
(Per-machine, hardware-optimized, zero code duplication)

---

## 0. TL;DR

1. Add the upstream flake once.  
2. Create **one** tiny overlay that turns the flake’s build-matrix into friendly attribute names (`llama-cpp-{cpu,cuda,vulkan}`).  
3. Import that overlay **once per host** (no globals, no cross-host pollution).  
4. Pick the right attribute in the host’s `modules` list.  
5. Delete the old dead code.

---

## 1. Add the new input

`flake.nix` (top of the `inputs` attrset):

```nix
  llama-cpp = {
    url  = "github:ggml-org/llama.cpp";
    inputs.nixpkgs.follows = "nixpkgs";   # keep single nixpkgs version
  };
```

Nothing else in the flake needs to change; all machines already receive
`specialArgs = { inherit inputs outputs; }`.

---

## 2. Create the overlay

File: `./nixos/overlays/llama-cpp.nix`

```nix
# Map the upstream flake’s build matrix to easy package names.
# This file is *imported*, not embedded, so it is lazy and host-agnostic.
{ inputs }: final: prev:
let
  inherit (inputs.llama-cpp.packages.${prev.system}) default cuda vulkan;
in
{
  llama-cpp-cpu    = default;                    # upstream already adds
  llama-cpp-cuda   = cuda;                       #   CPU flags if GGML_NATIVE=ON
  llama-cpp-vulkan = vulkan;
}
```

Notes
- We do **not** use `overrideAttrs` – the upstream flake already exposes the
  correctly configured derivations.
- `default` is built with `GGML_NATIVE=ON` (see upstream `package.nix`),
  therefore it auto-detects AVX/AVX2/AVX512/FMA on the build host.
- If you ever need *static* or *MPI* variants just add more attributes here
  the same way (`mpi-cpu = default.override { useMpi = true; };`).

---

## 3. Import the overlay **per host**

Your `nixosConfigurations` already contain a tiny anonymous module that adds
`overlay-stable`.  We do the same for the new overlay, but **only** for the
hosts that actually need `llama-cpp`.  This keeps closures small and avoids
rebuilding `nixpkgs` for every machine.

Example for a CUDA workstation (`carbon`):

```nix
carbon = inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs outputs; };
  modules = [
    ({ ... }: {
       nixpkgs.overlays = [
         (import ./nixos/overlays/llama-cpp.nix { inherit inputs; })
       ];
    })
    ./machines/carbon.nix
    ./nixos
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    { home-manager.useGlobalPkgs = true;
      home-manager.extraSpecialArgs = { inherit inputs outputs; };
    }
  ];
};
```

Do the analogous thing for the Vulkan laptop (`beryllium`):

```nix
beryllium = inputs.nixpkgs.lib.nixosSystem {
  ...
  modules = [
    ({ ... }: {
       nixpkgs.overlays = [
         (import ./nixos/overlays/llama-cpp.nix { inherit inputs; })
       ];
    })
    ./machines/beryllium.nix
    ...
  ];
};
```

CPU-only boxes (if any) get the same overlay; they will simply reference
`pkgs.llama-cpp-cpu`.

---

## 4. Consume the package

Wherever you actually declare packages—**inside the same configuration**—just
pick the attribute that matches the hardware.

`./machines/carbon.nix` (CUDA desktop):

```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-cuda
    git
    ...
  ];
}
```

`./machines/beryllium.nix` (Vulkan iGPU):

```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    llama-cpp-vulkan
    ...
  ];
}
```

Home-Manager usage is identical; the overlay makes the attributes available
there as well because Home-Manager inherits `pkgs` from NixOS.

---

## 5. Remove obsolete code

- Delete `./nixos/pkgs/llama-cpp-variants.nix` (your old `overrideAttrs`
  attempt).  
- If you previously pinned any `llama-cpp` fork in `inputs`, remove it.

---

## 6. Verify

```bash
# Preview what will be installed on carbon
nix eval .#nixosConfigurations.carbon.config.environment.systemPackages \
  --json | jq 'map(.name)' | grep llama

# Build & switch
nh os switch . --hostname carbon
```

Expected results  
- `llama-cpp-cuda` on carbon should have CUDA in its `cmakeFlags` and runtime
  closure.  
- `llama-cpp-vulkan` on beryllium should reference `vulkan-loader` etc.  
- CPU-only hosts pull in the light-weight `llama-cpp-cpu`.

---

## 7. Future tweaks

| Need | How |
|---|---|
| Static binary | `llama-cpp-static = default.override { enableStatic = true; };` |
| MPI support | `llama-cpp-mpi = default.override { useMpi = true; };` |
| Force specific CUDA arch | `cuda.override { cudaCapabilities = [ "8.9" ]; }` |
| Cross-compile for Windows | Use `inputs.llama-cpp.packages.x86_64-linux.windows` in the same overlay. |

All changes stay inside the single overlay file; no host modules need to be
edited.

---

## 8. Summary checklist

- [ ] Flake input `llama-cpp` added and follows `nixpkgs`.  
- [ ] `./nixos/overlays/llama-cpp.nix` created (≤ 10 lines).  
- [ ] Overlay imported **only** inside the `nixosConfigurations` that need it.  
- [ ] Host-specific modules reference `llama-cpp-{cpu,cuda,vulkan}`.  
- [ ] Old overlay / override file deleted.  
- [ ] `nix flake check` passes.  
- [ ] `nh os switch` succeeds on at least one host per variant.

You now have a hardware-optimized `llama.cpp` on every machine, zero dangling
code, and the freedom to extend the matrix later without touching host configs
again.