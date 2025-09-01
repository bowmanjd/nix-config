# Jonathan Bowman's Nix Configs

A comprehensive Nix flake configuration managing NixOS systems, Home Manager user environments, and custom packages. Supports multiple hosts and profiles with modular configurations.

## Quick Start

### Building and Switching Systems

For NixOS systems:
```bash
# Build and switch to lappy386 configuration
sudo nixos-rebuild switch --flake .#lappy386

# Build and switch to work configuration
sudo nixos-rebuild switch --flake .#work
```

## File Structure

```
.
├── flake.nix                    # Main flake definition with inputs and outputs
├── flake.lock                   # Lock file for all flake inputs
├── home-manager/                # Home Manager user configurations
│   ├── home.nix                 # Home profile
│   ├── work.nix                 # Work profile
│   ├── base/                    # Base configuration modules
│   │   ├── default.nix          # Base packages and settings
│   │   └── patches/             # Custom patches for packages
│   ├── fonts/                   # Font configurations
│   ├── guiapps/                 # GUI application settings
│   ├── nvim/                    # Neovim configuration
│   │   ├── lua/                 # Lua plugins and config
│   │   └── default.nix          # Neovim package definition
│   └── sway/                    # Sway window manager config
├── nixos/                       # NixOS system configurations
│   ├── base.nix                 # Base NixOS configuration
│   ├── lappy.nix                # Laptop-specific NixOS config
│   ├── work.nix                 # Work machine NixOS config
│   ├── hardware-configuration.nix # Hardware-specific settings
│   └── nixos-wsl/               # NixOS WSL subproject for work laptop
├── overlays/                    # Nixpkgs overlays
│   └── default.nix              # Custom package overlays
├── pkgs/                        # Custom package definitions
│   ├── default.nix              # Package collection
│   ├── basescripts/             # Basic utility scripts
│   ├── harlequin/               # Harlequin SQL client
│   ├── llama-swap/              # Llama model swapper
│   ├── llmscripts/              # LLM-related scripts
│   ├── mssql-*                  # MSSQL tools
│   └── workscripts/             # Work-specific scripts
├── secrets/                     # Encrypted secrets (age)
├── worksecrets/                 # Work-specific encrypted secrets
├── AGENTS.md                    # Development guide for LLM agents
├── CRUSH.md                     # Additional notes
├── notes.md                     # Personal notes
└── README.md                    # This file
```

## Key Components

### NixOS Configurations

- **lappy386**: Personal laptop configuration, user "bowmanjd"
- **work**: Work machine configuration, WSL, user "jbowman"
- **base.nix**: Shared NixOS settings applied to all systems
- **hardware-configuration.nix**: Auto-generated hardware-specific config

### Home Manager Profiles

- **home.nix**: Personal user environment with development tools, editors, and personal apps
- **work.nix**: Professional profile with work-specific tools and settings
- **base/**: Common user configuration modules
- **nvim/**: Neovim editor configuration with Lua plugins
- **sway/**: Sway window manager and Wayland configuration
- **llm/**: Anything related to language models, coding assistants etc.

### Custom Packages

Located in `pkgs/` directory:
- **basescripts**: Essential utility scripts (agegent, nixprepl, etc.)
- **harlequin**: Modern SQL client with TUI
- **llama-swap**: Tool for swapping Llama models
- **llmscripts**: Scripts for LLM interactions
- **mssql-***: Microsoft SQL Server tools
- **workscripts**: Work-specific automation scripts

## Development

### Secrets Management

Secrets are managed using age encryption:
- `secrets/`: Personal encrypted secrets
- `worksecrets/`: Work-specific encrypted secrets
- Use provided scripts for encryption/decryption

To encrypt for work:

```sh
printf plaintext-content-abcd1234| rage -a -R ~/nix-config/home-manager/worksecrets/age.key.pub > ~/nix-config/home-manager/worksecrets/secret_name.enc.txt
```

To encrypt for home:

```sh
printf plaintext-content-abcd1234| rage -a -R ~/nix-config/home-manager/secrets/age.key.pub > ~/nix-config/home-manager/secrets/secret_name.enc.txt
```

### Overlays

- **overlay-stable**: Provides access to stable nixpkgs channel
- **llama-cpp-optimized**: CPU-optimized llama.cpp build with AVX512 support
- **rust-overlay**: Latest Rust toolchain
- Additional overlays in `overlays/default.nix`