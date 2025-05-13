{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}: {
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "dotnet-sdk_6"
        "dotnet-core-combined"
        "dotnet-sdk-6.0.428"
        "dotnet-sdk-wrapped-6.0.428"
      ];
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      trusted-users = ["@wheel"];
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  networking = {
    firewall.enable = true;
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = true;
    };
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings = {
        #iptables = false;
        #ip6tables = false;
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    curl
    docker
    docker-compose
    fd
    git
    glibcLocalesUtf8
    gnutar
    home-manager
    iputils
    iproute2
    neovim
    nssTools
    openssh
    p7zip
    podman
    podman-compose
    python3
    ripgrep
    sudo
    tree
    wget
    zip
  ];

  services.tailscale.enable = true;

  programs.bash = {
    completion.enable = true;
    vteIntegration = true;
  };

  environment.unixODBCDrivers = with pkgs.unixODBCDrivers; [
    msodbcsql18
  ];

  services.openssh = {
    enable = true;
    # Forbid root login through SSH.
    settings.PermitRootLogin = "no";
    # Use keys only. Remove if you want to SSH using password (not recommended)
    settings.PasswordAuthentication = false;
    ports = [ 5788 ];
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "localhost".extraConfig = ''
        reverse_proxy 127.0.0.1:8000
        tls internal
      '';
      "*.home.arpa" = {
        serverAliases = ["*.local.bowmanjd.com" "*.dev.internal"];
        logFormat = "output file ${config.services.caddy.logDir}/access-local.log";
        extraConfig = ''
          @startsWithPort header_regexp Host ^\d+
          reverse_proxy @startsWithPort 127.0.0.1:{re.0}
          tls internal
        '';
      };
    };
  };


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
