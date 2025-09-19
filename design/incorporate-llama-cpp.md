# Plan: Incorporate `llama.cpp` from an External Flake

This plan outlines the steps to replace the `llama-cpp` package from Nixpkgs with customized versions from the official `ggml-org/llama.cpp` flake.

This approach provides multiple, optimized package variants that can be selected on a per-machine basis (e.g., for CUDA, Vulkan, or CPU-specific optimizations).

## Step 1: Add the `llama.cpp` Flake Input

First, you must declare the external `llama.cpp` repository as an input in your primary `flake.nix` file. This makes the flake's packages and overlays available to your configuration.

**Action:** Modify `/home/bowmanjd/devel/caleb-nix/flake.nix`.

Add the following snippet within the `inputs` attribute set:

```nix
# In /home/bowmanjd/devel/caleb-nix/flake.nix
inputs = {
  # ... other inputs

  llama-cpp = {
    url = "github:ggml-org/llama.cpp";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # ... other inputs
};
```

## Step 2: Create the Custom Variants Overlay

Create a new overlay file that defines the different `llama-cpp` package variants you need. This overlay will use the `llama-cpp` flake input we just added.

**Action:** Create a new file named `nixos/pkgs/llama-cpp-variants.nix`.

**Content for the new file:**

```nix
# /home/bowmanjd/devel/caleb-nix/nixos/pkgs/llama-cpp-variants.nix
#
# This overlay provides customized `llama-cpp` packages using the external flake.
# It pulls pre-built variants for CUDA and Vulkan directly from the flake,
# and provides a CPU-optimized version by adding specific cmake flags.

inputs: final: prev: {

  # 1. CPU-optimized build
  # We take the default package and override it with CPU-specific flags
  # for maximum performance on non-GPU machines.
  llama-cpp-cpu = inputs.llama-cpp.packages.${prev.system}.default.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
      "-DGGML_NATIVE=ON"
      "-DGGML_AVX=ON"
      "-DGGML_AVX2=ON"
      "-DGGML_FMA=ON"
      "-DGGML_OPENMP=ON"
      "-DLLAMA_BUILD_SERVER=ON"
    ];
  });

  # 2. CUDA-accelerated build
  # The flake already builds this for us.
  llama-cpp-cuda = inputs.llama-cpp.packages.${prev.system}.cuda;

  # 3. Vulkan-accelerated build
  # The flake also builds a Vulkan-enabled package.
  llama-cpp-vulkan = inputs.llama-cpp.packages.${prev.system}.vulkan;

}
```

## Step 3: Apply the New Overlay

To make the new packages available, you must add the overlay to your NixOS configuration. A good central place for this would be `nixos/default.nix`, as it appears to be imported by all your machine configurations.

**Action:** Modify `/home/bowmanjd/devel/caleb-nix/nixos/default.nix`.

You will need to add the `import` line to your `nixpkgs.overlays` list.

```nix
# In /home/bowmanjd/devel/caleb-nix/nixos/default.nix
{ inputs, ... }: {
  imports = [
    # ... other imports
  ];

  nixpkgs.overlays = [
    # ... any existing overlays
    (import ../pkgs/llama-cpp-variants.nix inputs)
  ];

  # ... rest of your configuration
}
```
*(Note: The exact structure of your `nixos/default.nix` might differ. The key is to add the `import` line to the `nixpkgs.overlays` list.)*

## Step 4: Usage in Machine Configurations

With the overlay applied, you can now use the new packages in any of your machine-specific configurations.

**Example Usage:**

-   On a machine with a NVIDIA GPU (e.g., `machines/carbon.nix`), you can add:
    ```nix
    environment.systemPackages = with pkgs; [
      # ... other packages
      llama-cpp-cuda
    ];
    ```

-   On a machine where you want the CPU-optimized version, you can add:
    ```nix
    environment.systemPackages = with pkgs; [
      # ... other packages
      llama-cpp-cpu
    ];
    ```

## Step 5: Cleanup (Recommended)

To avoid confusion, it is recommended to remove the old, non-functional overlay file.

**Action:** Delete the file `/home/bowmanjd/devel/caleb-nix/nixos/pkgs/llama-cpp-overlays.nix`.

```bash
rm /home/bowmanjd/devel/caleb-nix/nixos/pkgs/llama-cpp-overlays.nix
```