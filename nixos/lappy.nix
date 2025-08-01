# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    ./base.nix
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "lappy386";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
    resolvconf.useLocalResolver = true;
  };

  nix.settings.trusted-users = ["root"];

  systemd.services.NetworkManager-wait-online.enable = false;

  boot.blacklistedKernelModules = ["psmouse"];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.extraEntries = {
    "fedora.conf" = ''
      title Fedora
      efi /EFI/fedora/shim.efi
    '';
  };
  hardware.bluetooth.enable = true; # enables support for Bluetooth

  services.printing.enable = true;
  services.printing.drivers = [pkgs.cups-brother-hll2350dw];

  services.ollama.enable = true;

  services.dnsmasq = {
    enable = true;
    settings = {
      address = [
        "/home.arpa/127.0.0.1"
        "/dev.internal/127.0.0.1"
        "/local.bowmanjd.com/127.0.0.1"
      ];
      cache-size = 2000;
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    # for a WiFi printer
    openFirewall = true;
  };

  users.users = {
    bowmanjd = {
      # Be sure to change it (using passwd) after rebooting!
      initialPassword = "Insecure123";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
      ];
      extraGroups = ["audio" "wheel" "networkmanager" "plugdev" "video"];
    };
  };

  services.tailscale.enable = true;

  services.thermald.enable = true;

  environment.systemPackages = with pkgs; [
    nss_latest
    cmake
  ];

  services.fprintd = {
    enable = true;
    package = pkgs.fprintd-tod;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
    };
  };

  #sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  programs.dconf.enable = true;

  # Needed for sway
  security.polkit.enable = true;
  security.pam.services.swaylock = {};

  # Allows for updating firmware via `fwupdmgr`.
  services.fwupd.enable = true;
}
