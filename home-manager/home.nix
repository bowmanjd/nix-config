{
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ./nvim
    ./fonts
    ./sway
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
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
    calibre
    cargo
    degit
    dockerfile-language-server-nodejs
    dprint
    du-dust
    easyeffects
    eslint_d
    eza
    ffmpeg_6-full
    fzf
    gimp
    glow
    go
    helvum
    htop
    inkscape
    jq
    jql
    libgourou
    libreoffice-fresh
    microsoft-edge
    neofetch
    nmap
    nodePackages_latest.bash-language-server
    nodePackages_latest.poor-mans-t-sql-formatter-cli
    nodePackages_latest.prettier
    nodePackages_latest.pyright
    openttd
    p7zip
    pavucontrol
    pinentry
    podman
    prettierd
    prismlauncher
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
    quick-lint-js
    rage
    rustc
    skopeo
    sqlcmd
    sqlfluff
    starship
    stylelint
    stylua
    unixODBCDrivers.msodbcsql18
    vhs
    virtualenv
    #visidata
    vscode-langservers-extracted
    yaml-language-server
    yt-dlp
  ];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
  };
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
  home.file."scripts" = {
    enable = true;
    executable = true;
    recursive = true;
    source = ./scripts;
    target = "./.local/bin";
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
