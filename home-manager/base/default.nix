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

  imports = [
    ./basescripts.nix
  ];


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
      . $HOME/.local/bin/sshagent
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
    gcc
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
    sops
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

