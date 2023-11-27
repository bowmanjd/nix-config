{
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
      export DIRENV_LOG_FORMAT=
      export PINENTRY_PROGRAM="$(command -v pinentryutf8)"
      . $(command -v sshagent)
    '';
    shellAliases = {
      ls1 = "eza -1 --icons=never";
    };
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    lfs.enable = true;
    userName = "Jonathan Bowman";
    ignores = [
      ".envrc"
      "[._]*.s[a-v][a-z]"
      "!*.svg"
      "[._]*.sw[a-p]"
      "[._]s[a-rt-v][a-z]"
      "[._]ss[a-gi-z]"
      "[._]sw[a-p]"
      "Session.vim"
      "Sessionx.vim"
      ".netrwhist"
      "*~"
      "[._]*.un~"
    ];
    extraConfig = {
      core.editor = "nvim";
      pull.rebase = true;
      diff.colorMoved = "zebra";
      fetch.prune = true;
      init.defaultBranch = "main";
      push = {
        autoSetupRemote = true;
        default = "simple";
      };
      commit.gpgsign = true;
      gpg.format = "ssh";
    };
  };

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
    settings = {
      command_timeout = 2000;
      env_var = {
        CUSTOMER = {
          format = "(to [$env_value](bold green)) ";
        };
      };
    };
  };

  home.packages = with pkgs; [
    age
    alejandra
    basescripts
    bat
    bc
    buildah
    cargo
    degit
    dig
    dogdns
    dnsutils
    du-dust
    elinks
    eza
    ffmpeg_6-full
    file
    gcc
    gitui
    glow
    go
    htop
    html-tidy
    inetutils
    jq
    jql
    libgourou
    mssql-bcp
    ms-sqltoolsservice
    mssql-cli
    mssql-scripter
    ncftp
    neofetch
    nix-index
    nmap
    p7zip
    pinentry
    podman
    powershell
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
        rich
        setuptools
        tidylib
        types-beautifulsoup4
        weasyprint
        wheel
      ]))
    qrencode
    rage
    rich-cli
    rustc
    rust-analyzer
    see
    shiori
    skopeo
    sops
    sqlcmd
    sqlfluff
    sqlite
    starship
    unixODBCDrivers.msodbcsql18
    vhs
    virtualenv
    yt-dlp
  ];

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

