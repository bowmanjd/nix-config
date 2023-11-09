{
  pkgs,
  ...
}: {
  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
    };
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";

  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    historyControl = ["erasedups" "ignoredups" "ignorespace"];
    bashrcExtra = ''
      export PINENTRY_PROGRAM="$HOME/.local/bin/pinentryutf8"
      export LC_CTYPE="en_US.UTF-8"
      . $HOME/.local/bin/sshagent
    '';
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.ssh = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableAliases = true;
    git = true;
    icons = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  home.packages = with pkgs; [
    age
    alejandra
    bat
    bc
    buildah
    cargo
    degit
    du-dust
    eza
    ffmpeg_6-full
    gitui
    glow
    go
    htop
    jq
    jql
    libgourou
    neofetch
    nmap
    p7zip
    pinentry
    podman
    (python311.withPackages (ps:
      with ps; [
        bandit
        beautifulsoup4
        black
        cmarkgfm
        eradicate
        fire
        flake8
        flake8-bugbear
        flake8-docstrings
        fonttools
        isort
        lxml
        pep8-naming
        pexpect
        pip
        ptpython
        pynvim
        pytest
        reorder-python-imports
        setuptools
        types-beautifulsoup4
        weasyprint
        wheel
      ]))
    qrencode
    rage
    rustc
    skopeo
    sqlcmd
    sqlfluff
    starship
    unixODBCDrivers.msodbcsql18
    vhs
    virtualenv
    yt-dlp
  ];

  # copy files to ~/.local/bin
  home.file."agegent" = {
    enable = true;
    executable = true;
    source = ./scripts/agegent;
    target = "./.local/bin/agegent";
  };

  home.file."cleanage" = {
    enable = true;
    executable = true;
    source = ./scripts/cleanage;
    target = "./.local/bin/cleanage";
  };

  home.file."pinentryutf8" = {
    enable = true;
    executable = true;
    source = ./scripts/pinentryutf8;
    target = "./.local/bin/pinentryutf8";
  };

  home.file."sshagent" = {
    enable = true;
    executable = true;
    source = ./scripts/sshagent;
    target = "./.local/bin/sshagent";
  };

  home.file."superscript" = {
    enable = true;
    executable = true;
    source = ./scripts/superscript;
    target = "./.local/bin/superscript";
  };

  systemd.user.services = {
    "cleanage" = {
      Unit = {
        Description = "Remove any stale unencrypted artifacts";
      };
      Service = {
        ExecStart = "%h/.local/bin/cleanage";
        Type = "oneshot";
      };
    };
  };

  systemd.user.timers = {
    "cleanage" = {
      Unit = {
        Description = "Run stale unencrypted artifact cleanup regularly";
      };
      Timer = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec="5min";
      };
      Install = {
        wantedBy = [ "timers.target" ];
      };
    };
  };
}

