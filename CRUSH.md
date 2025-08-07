# CRUSH.md

Project: nix-config (Nix flake with NixOS, Home Manager, custom pkgs; includes C# launcher, Rust utils, docs)

Build/test/lint
- Nix flake checks: nix flake check
- Build all packages: nix build .#packages.x86_64-linux
- Build specific package: nix build .#<attr>
- Build NixOS config (host): sudo nixos-rebuild switch --flake .#<hostname>
- Home Manager switch: home-manager switch --flake .#<profile>
- Format Nix: nix fmt
- Lint Nix (nixpkgs-fmt): nix build .#checks.x86_64-linux.nixpkgs-fmt
- Shell for dev: nix develop

WSL distro (nixos-wsl)
- Build tarball: nix build .#nixos-wsl.tarball
- Run repo CI checks: nix build .#checks.x86_64-linux
- Docs site: nix build .#nixos-wsl-docs

Rust utils (nixos-wsl/utils)
- Dev shell: nix develop .#nixos-wsl-utils
- Build: cargo build --manifest-path nixos/wsl/utils/Cargo.toml
- Test: cargo test --manifest-path nixos/wsl/utils/Cargo.toml
- Single test: cargo test <test_name> -- --exact --nocapture
- Format: nix build .#checks.x86_64-linux.rustfmt

C# Launcher (nixos-wsl/Launcher)
- Dev shell: nix develop .#nixos-wsl-launcher
- Build: dotnet build nixos/nixos-wsl/Launcher/Launcher.sln -c Release
- Test (if tests added): dotnet test <sln_or_csproj> -c Release --filter FullyQualifiedName~<Name>
- Format: nix build .#checks.x86_64-linux.dotnet-format

Powershell tests (nixos-wsl/tests)
- Run all: pwsh -NoProfile -File nixos/nixos-wsl/tests/run.ps1 (or see workflows/run_tests.yml)
- Run single: pwsh -NoProfile -File nixos/nixos-wsl/tests/<suite>/<name>.Tests.ps1 -Tag <Tag>

Code style
- Nix: nixfmt / nixpkgs-fmt; 2-space indent; attrset keys kebab-case; prefer let/in and with sparingly; no impure fetchers
- Rust: rustfmt defaults; clippy clean; Result/anyhow for errors; prefer ? over unwrap; modules snake_case; types UpperCamelCase; functions snake_case
- C#: dotnet-format; nullable enabled; var for obvious types; PascalCase for types/methods, camelCase for locals/params; async Task/ValueTask; use using declarations; exceptions not return codes
- PowerShell: Pester-style tests; PascalCase functions; set-StrictMode -Version Latest; no Write-Host in libs
- Imports: group/std first then external then local; alphabetical within groups; no unused imports
- Types: be explicit at public boundaries; prefer interfaces for DI
- Errors: bubble up with context; no panics in libs; log at edges only

Notes
- See .github/workflows for CI equivalents (run_checks, run_tests, run_docs)
- No Cursor/Copilot rule files detected
