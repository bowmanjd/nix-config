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
      export PINENTRY_PROGRAM="$(command -v pinentryutf8)"
      . $(command -v sshagent)
      osc7_cwd() {
          local strlen=''${#PWD}
          local encoded=""
          local pos c o
          for (( pos=0; pos<strlen; pos++ )); do
              c=''${PWD:$pos:1}
              case "$c" in
                  [-/:_.!\'\(\)~[:alnum:]] ) o="''${c}" ;;
                  * ) printf -v o '%%%02X' "''\'''${c}" ;;
              esac
              encoded+="''${o}"
          done
          printf '\e]7;file://%s%s\e\\' "''${HOSTNAME}" "''${encoded}"
      }
      PROMPT_COMMAND=''${PROMPT_COMMAND:+$PROMPT_COMMAND; }osc7_cwd
    '';
    shellAliases = {
      ls1 = "eza -1 --icons=never";
    };
  };

  programs.bash.initExtra = ". ${pkgs.git}/share/bash-completion/completions/git-prompt.sh";

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

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
    "$HOME/.dotnet/tools"
  ];

  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    lfs.enable = true;
    userName = "Jonathan Bowman";
    ignores = [
      ".envrc"
      ".sqltun"
      "[._]*.s[a-v][a-z]"
      "!*.svg"
      "[._]*.sw[a-p]"
      "[._]s[a-rt-v][a-z]"
      "[._]ss[a-gi-z]"
      "[._]sw[a-p]"
      ".aider*"
      "Session.vim"
      "Sessionx.vim"
      ".netrwhist"
      "*~"
      "[._]*.un~"
    ];
    difftastic.enable = true;
    extraConfig = {
      core.editor = "nvim";
      core.autocrlf = false;
      pull.rebase = true;
      diff.colorMoved = "zebra";
      fetch.prune = true;
      init.defaultBranch = "main";
      push = {
        autoSetupRemote = true;
        default = "simple";
      };
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.format = "ssh";
      rerere.enabled = true;
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

  programs.zellij = {
    enable = true;
    enableBashIntegration = false;
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
    secureSocket = false;
    extraConfig = ''
      bind | split-window -h
      bind - split-window -v

      set -g @catppuccin_flavor "mocha"
      set -g @catppuccin_window_status_style "rounded"
    '';
    plugins = with pkgs; [
      # tmuxPlugins.cpu
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g mouse on
          set -g default-terminal "tmux-256color"
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
          set -g status-right-length 100
          set -g status-left-length 100
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_application}"
          set -ag status-right "#{E:@catppuccin_status_session}"
          set -ag status-right "#{E:@catppuccin_status_uptime}"
        '';
      }
    ];
  };

  programs.ssh.matchBlocks = {
    "server" = {
      hostname = "10.0.0.5";
      user = "bowman4";
      port = 22;
      forwardAgent = true;
    };
    "boron" = {
      hostname = "10.0.0.10";
      user = "boron";
      port = 22;
      forwardAgent = true;
    };
    "nitrogen" = {
      hostname = "10.0.0.11";
      user = "nitrogen";
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
    "tun" = {
      hostname = "129.213.98.217";
      user = "jbowman";
      port = 5517;
    };
  };

  programs.direnv = {
    config = {
      log_format = "-";
      warn_timeout = "45s";
    };
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      command_timeout = 5000;
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
    argc
    basescripts
    bat
    bc
    broot
    buildah
    bun
    cachix
    cargo
    cargo-binstall
    cargo-insta
    clippy
    cobra-cli
    comrak
    corepack_22
    dblab
    #degit
    #delta
    #deno
    devbox
    devenv
    diff-so-fancy
    dig
    distrobox
    dogdns
    dotacat
    dotnet-repl
    dotnet-sdk
    dnsutils
    du-dust
    elinks
    eza
    ffmpeg_6-full
    file
    flatbuffers
    #frogmouth
    gcc
    gh
    #gitbutler
    gitoxide
    gitui
    git-subrepo
    glow
    gnumake
    gnupg
    go
    handlr
    #harlequin
    # harlequin-odbc
    htop
    html-tidy
    imagemagick
    inetutils
    inotify-tools
    jq
    jql
    lazygit
    lftp
    libgdiplus
    libgourou
    libpcap
    lilipod
    lsix
    miller
    mono
    mssql-bcp
    ms-sqltoolsservice
    mssql-cli
    mssql-scripter
    ncdu
    #ncftp
    neofetch
    nix-index
    nmap
    nodejs_22
    openssl
    pandoc
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
        #flake8-bugbear
        flake8-docstrings
        fonttools
        isort
        lxml
        numpy
        #numpy_1
        onnxruntime
        pep8-naming
        pexpect
        pip
        ptpython
        pynvim
        pytest
        reorder-python-imports
        rich
        rich-rst
        setuptools
        #textual
        tidylib
        types-beautifulsoup4
        weasyprint
        wheel
        hf-transfer
        hf-xet
        huggingface-hub
        litellm
        wordcloud
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
    sl
    see
    shiori
    skim
    skopeo
    sops
    sqlcmd
    sqlfluff
    sqlite
    starship
    swc
    tokei
    #toolong
    unixODBCDrivers.msodbcsql18
    usql
    uv
    vhs
    virtualenv
    watchexec
    yq
    yt-dlp
    unzip
    xdg-utils
    xh
    xxHash
    zbar
    zip
    zola
  ];

  systemd.user.services = let
    scriptpath = lib.makeBinPath [pkgs.basescripts];
  in {
    "cleanage" = {
      Unit = {
        Description = "Remove any stale unencrypted artifacts";
        After = ["default.target"];
        Wants = ["default.target"];
      };
      Service = {
        ExecStart = "${pkgs.bun}/bin/bun ${scriptpath}/cleanage.js";
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
        WantedBy = ["timers.target"];
      };
    };
  };

  xdg.configFile."mssqlcli.config" = {
    enable = true;
    source = ./mssqlcli.config;
    target = "mssqlcli/config";
  };

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk}/share/dotnet";
  };
}
