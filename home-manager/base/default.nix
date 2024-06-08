{
  lib,
  pkgs,
  outputs,
  ...
}: {
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

  programs.bash.initExtra = ". ${pkgs.git}/share/bash-completion/completions/git-prompt.sh";

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    flags = [
      "--disable-up-arrow"
    ];
    #settings = {
    #  sync_frequency = "10m";
    #  filter_mode_shell_up_key_binding = "session";
    #};
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
      core.autocrlf = "input";
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
      filter.ageencrypt = {
        required = true;
        clean = "rage -r age1npc2n2mytn0u62s6qj2ymh9caavevh9z7ttfhperzj0uyxfnffmst0wrlf -r age1tsnykfpw5t8ce6lckl3exk7fyqulc3n23vmasqrlapw42d6ff5us9mld9v -a -";
        smudge = "agegent";
      };
    };
  };

  programs.ssh = {
    enable = true;
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    customPaneNavigationAndResize = true;
    escapeTime = 0;
    historyLimit = 5000;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    newSession = true;
    terminal = "screen-256color";
    tmuxinator.enable = true;
    extraConfig = ''
      bind | split-window -h
      bind - split-window -v
    '';
  };

  programs.ssh.matchBlocks = {
    "server" = {
      hostname = "192.168.0.5";
      user = "bowman4";
      port = 22;
      forwardAgent = true;
    };
    "percheron" = {
      hostname = "129.213.21.111";
      user = "bowmanjd";
      port = 2227;
      forwardAgent = true;
    };
    "haflinger" = {
      hostname = "132.145.175.236";
      user = "bowmanjd";
      port = 2227;
      forwardAgent = true;
    };
    "belgian" = {
      hostname = "132.145.212.196";
      user = "bowmanjd";
      port = 2227;
      forwardAgent = true;
    };
    "breton" = {
      hostname = "138.197.14.170";
      user = "bowmanjd";
      port = 2227;
      forwardAgent = true;
    };
    "clydesdale" = {
      hostname = "104.154.208.5";
      user = "bowmanjd";
      port = 2227;
      forwardAgent = true;
    };
    "github" = {
      hostname = "ssh.github.com";
      user = "git";
      port = 443;
    };
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;
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
    broot
    buildah
    cachix
    cargo
    cargo-binstall
    cargo-insta
    clippy
    cobra-cli
    comrak
    degit
    delta
    diff-so-fancy
    dig
    dogdns
    dnsutils
    du-dust
    elinks
    eza
    ffmpeg_6-full
    file
    flatbuffers
    gcc
    gitui
    glow
    gnumake
    gnupg
    go_1_22
    handlr
    htop
    html-tidy
    inetutils
    jq
    jql
    lftp
    libgdiplus
    libgourou
    libpcap
    miller
    mssql-bcp
    ms-sqltoolsservice
    mssql-cli
    mssql-scripter
    ncdu
    ncftp
    neofetch
    nix-index
    nmap
    nodejs
    openssl
    p7zip
    pinentry
    podman
    powershell
    (python3.withPackages (ps:
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
        #langchain
        llama-index-core
        llama-index-program-openai
        llama-index-llms-openai
        llama-index-llms-openai-like
        llama-index-llms-ollama
        llama-index-embeddings-openai
        llama-index-embeddings-ollama
        llama-index-embeddings-huggingface
        llama-index-readers-file
        llama-index-readers-json
        llama-index-readers-database
        llama-index-vector-stores-qdrant
        llama-index-vector-stores-chroma
        lxml
        pathtools
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
    #qsv
    rage
    #rich-cli
    repgrep
    rustc
    rustfmt
    rust-analyzer
    sad
    sd
    see
    shiori
    skim
    skopeo
    sops
    sqlcmd
    sqlfluff
    sqlite
    starship
    tokei
    unixODBCDrivers.msodbcsql18
    usql
    vhs
    virtualenv
    xsv
    yt-dlp
    unzip
    xdg-utils
    xxHash
    zip
    zola
    zoxide
  ];

  systemd.user.services = let
    scriptpath = lib.makeBinPath [ pkgs.basescripts ];
  in {
    "cleanage" = {
      Unit = {
        Description = "Remove any stale unencrypted artifacts";
      };
      Service = {
        ExecStart = lib.concatStrings [ scriptpath "/cleanage" ];
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
        RandomizedDelaySec = "5min";
      };
      Install = {
        wantedBy = ["timers.target"];
      };
    };
  };

  xdg.configFile."mssqlcli.config" = {
    enable = true;
    source = ./mssqlcli.config;
    target = "mssqlcli/config";
  };
}
