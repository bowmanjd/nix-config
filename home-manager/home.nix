{
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    ./nvim
    ./fonts
    ./sway
    ./guiapps
  ];

  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "bowmanjd";
    homeDirectory = "/home/bowmanjd";
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

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    historyControl = ["erasedups" "ignoredups" "ignorespace"];
    profileExtra = ''
      [ "$(tty)" = "/dev/tty1" ] && exec sway
    '';
    bashrcExtra = ''
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
      export PINENTRY_PROGRAM="$HOME/.local/bin/pinentryutf8"
      export LC_CTYPE="en_US.UTF-8"
      . $HOME/.local/bin/sshagent
    '';
  };
  programs.ssh = {
    enable = true;
  };
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    lfs.enable = true;
    userName = "Jonathan Bowman";
    userEmail = "git@bowmanjd.com";
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
      user.signingKey = builtins.readFile ./secrets/id_ed25519.pub;
    };
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

  home.file."secrets" = {
    enable = true;
    recursive = true;
    source = ./secrets;
    target = ".ssh/secrets";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
  home.sessionVariables = {
    EMAIL = "git@bowmanjd.com";
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
