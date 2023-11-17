{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {

  nixpkgs = {
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
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
    };
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = true;
    };
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    curl
    docker
    fd
    git
    glibcLocalesUtf8
    gnutar
    home-manager
    iputils
    iproute2
    neovim
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

  #environment.etc."odbcinst.ini".text = ''
  #  [ODBC Driver 18 for SQL Server]
  #  Description=Microsoft ODBC Driver 18 for SQL Server
  #  Driver=${lib.makeLibraryPath [ pkgs.unixODBCDrivers.msodbcsql18 ]}/libmsodbcsql-18.1.so.1.1
  #  
  #'';
  environment.unixODBCDrivers = with pkgs.unixODBCDrivers; [
    msodbcsql18
  ];

# fd -t f libmsodbcsql-18 /nix/store | head -n 1

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    # Forbid root login through SSH.
    settings.PermitRootLogin = "no";
    # Use keys only. Remove if you want to SSH using password (not recommended)
    settings.PasswordAuthentication = false;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
