AGENTS guide for nix-config (Nix flake with NixOS, Home Manager, custom pkgs; plus Rust, C#, PowerShell)

Build/lint/test
- Flake checks: nix flake check
- Build all pkgs: nix build .#packages.$(nix eval --raw --impure --expr builtins.currentSystem)
- Build attr: nix build .#<attr>
- NixOS switch (host): sudo nixos-rebuild switch --flake .#<hostname>
- Home Manager: home-manager switch --flake .#<profile>
- Nix fmt: nix fmt; lint: nix build .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).nixpkgs-fmt
- Dev shell: nix develop

WSL subproj (nixos/nixos-wsl)
- Tarball: nix build .#nixos-wsl.tarball; docs: nix build .#nixos-wsl-docs
- CI checks: nix build .#checks.$(nix eval --raw --impure --expr builtins.currentSystem)
- PowerShell tests (Windows only):
  - All: pwsh -NoProfile -File nixos/nixos-wsl/tests/run.ps1
  - Single: pwsh -NoProfile -File nixos/nixos-wsl/tests/<suite>/<name>.Tests.ps1 -Tag <Tag>

Rust utils (nixos/nixos-wsl/utils)
- Build: cargo build --manifest-path nixos/nixos-wsl/utils/Cargo.toml
- Test: cargo test --manifest-path nixos/nixos-wsl/utils/Cargo.toml
- Single test: cargo test <test_name> -- --exact --nocapture
- Format/lint: nix build .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).rustfmt

C# Launcher (nixos/nixos-wsl/Launcher)
- Build: dotnet build nixos/nixos-wsl/Launcher/Launcher.sln -c Release
- Test (if present): dotnet test <sln_or_csproj> -c Release --filter FullyQualifiedName~<Name>
- Format: nix build .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).dotnet-format

Code style
- Nix: nixfmt/nixpkgs-fmt; 2-space; kebab-case attr keys; minimal with; no impure fetchers
- Rust: rustfmt; clippy-clean; anyhow/thiserror; prefer ?; no unwrap in libs; snake_case fns/modules; UpperCamelCase types
- C#: dotnet-format; nullable enabled; var for obvious; PascalCase types/methods; camelCase locals/params; async Task/ValueTask; using declarations; throw exceptions
- PowerShell: Pester tests; PascalCase functions; Set-StrictMode -Version Latest; avoid Write-Host in libs
- Imports: std/core first, then external, then local; alphabetical in groups; no unused
- Types/errors: explicit at public boundaries; propagate with context; log at edges only

Notes
- No Cursor (.cursor/rules/ or .cursorrules) or Copilot (.github/copilot-instructions.md) rule files found.
