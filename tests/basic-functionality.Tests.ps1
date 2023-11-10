BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Basic Functionality" {
  BeforeAll {
    $distro = Install-Distro
  }

  It "is possible to run a command in the container" {
    $distro.Launch("nixos-version")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a second command" {
    $distro.Launch("true")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command after restarting the container" {
    $distro.Shutdown()
    $distro.Launch("true")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to use nixos-rebuild" {
    $distro.Launch("sudo nixos-rebuild switch")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command through nix-shell" {
    $distro.Launch("nix-shell -p neofetch --command neofetch")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command through nix run" {
    $distro.Launch("nix --extra-experimental-features 'nix-command flakes' run nixpkgs#neofetch")
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    $distro.Uninstall()
  }
}
