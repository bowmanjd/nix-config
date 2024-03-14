# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
    ./nixos-wsl/modules
    ./base.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "jbowman";

  networking = {
    hostName = "jbowman-cargas";
  };

  nix.settings.trusted-users = [ "root" "jbowman" ];
  
  users.users = {
    jbowman = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
      ];
      extraGroups = [ "wheel" ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
