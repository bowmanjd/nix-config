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

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    age
    alejandra
    fira-code
    fira-code-symbols
    font-awesome
    liberation_ttf
    mplus-outline-fonts.githubRelease
    nerdfonts
    noto-fonts
    noto-fonts-emoji
    proggyfonts
    bat
    bc
    brightnessctl
    buildah
    calibre
    cargo
    clipman
    degit
    dockerfile-language-server-nodejs
    dprint
    du-dust
    easyeffects
    eslint_d
    eza
    ffmpeg_6-full
    foot
    fuzzel
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
    sqlfluff
    starship
    stylelint
    stylua
    swayidle
    unixODBCDrivers.msodbcsql18
    vhs
    virtualenv
    #visidata
    vscode-langservers-extracted
    waybar
    wl-clipboard
    wob
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
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "Hack Nerd Font:size=14";
      };
      cursor = {
        color = "111111 cccccc";
      };
      colors = {
        foreground = "cdd6f4"; # Text
        background = "000000"; # Base
        regular0 = "45475a"; # Surface 1
        regular1 = "f38ba8"; # red
        regular2 = "a6e3a1"; # green
        regular3 = "f9e2af"; # yellow
        regular4 = "89b4fa"; # blue
        regular5 = "f5c2e7"; # pink
        regular6 = "94e2d5"; # teal
        regular7 = "bac2de"; # Subtext 1
        bright0 = "585b70"; # Surface 2
        bright1 = "f38ba8"; # red
        bright2 = "a6e3a1"; # green
        bright3 = "f9e2af"; # yellow
        bright4 = "89b4fa"; # blue
        bright5 = "f5c2e7"; # pink
        bright6 = "94e2d5"; # teal
        bright7 = "a6adc8"; # Subtext 0
        # foreground = "dddddd";
        # background = "000000";
        # regular0 = "000000";  # black
        # regular1 = "cc0403";  # red
        # regular2 = "19cb00";  # green
        # regular3 = "cecb00";  # yellow
        # regular4 = "0d73cc";  # blue
        # regular5 = "cb1ed1";  # magenta
        # regular6 = "0dcdcd";  # cyan
        # regular7 = "dddddd";  # white
        # bright0 = "767676";   # bright black
        # bright1 = "f2201f";   # bright red
        # bright2 = "23fd00";   # bright green
        # bright3 = "fffd00";   # bright yellow
        # bright4 = "1a8fff";   # bright blue
        # bright5 = "fd28ff";   # bright magenta
        # bright6 = "14ffff";   # bright cyan
        # bright7 = "ffffff";   # bright white
      };
    };
  };
  programs.eza = {
    enable = true;
    enableAliases = true;
    git = true;
    icons = true;
  };

  wayland.windowManager.sway = {
    enable = true;
    extraConfigEarly = "set $wobsock $XDG_RUNTIME_DIR/wob.sock";
    config = rec {
      modifier = "Mod4";
      terminal = "foot";
      startup = [
        {command = "wl-paste -t text --watch clipman store --max-items=500";}
        {command = "~/.local/bin/idle";}
        {command = "rm -f $wobsock && mkfifo $wobsock && tail -f $wobsock | wob";}
      ];
      bars = [
        {
          command = "waybar";
        }
      ];
      input = {
        "1739:52710:DLL0945:00_06CB:CDE6_Touchpad" = {
          dwt = "enabled";
          tap = "enabled";
          middle_emulation = "enabled";
        };
      };
      output = {
        "*" = {
          bg = "#000000 solid_color";
        };
      };
      window = {
        border = 0;
        hideEdgeBorders = "both";
      };
      menu = "fuzzel -p 'Run:'";
      fonts = {
        names = ["Hack Nerd Font"];
        size = 11.0;
      };
      keybindings = {
        "${modifier}+Shift+w" = "exec firefox";
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+d" = "exec ${menu}";
        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+d" = "exec ~/.local/bin/touchpad.py toggle";
        "${modifier}+Shift+e" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
        "${modifier}+b" = "splith";
        "${modifier}+v" = "splitv";
        "${modifier}+s" = "layout stacking";
        "${modifier}+w" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";
        "${modifier}+f" = "fullscreen";
        "${modifier}+r" = "mode \"resize\"";

        "${modifier}+Left" = "focus left";
        "${modifier}+Down" = "focus down";
        "${modifier}+Up" = "focus up";
        "${modifier}+Right" = "focus right";
        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";
        "${modifier}+Shift+Left" = "move left";
        "${modifier}+Shift+Down" = "move down";
        "${modifier}+Shift+Up" = "move up";
        "${modifier}+Shift+Right" = "move right";

        "${modifier}+Shift+q" = "kill";
        "${modifier}+Shift+space" = "floating toggle";
        "${modifier}+space" = "mode_toggle";
        "${modifier}+a" = "focus parent";
        "${modifier}+Shift+minus" = "move scratchpad";
        "${modifier}+minus" = "scratchpad show";
        "${modifier}+question" = "exec ~/.local/bin/bemoji -n";
        "Print" = "exec ~/.local/bin/screencap";
        "${modifier}+m" = "exec makoctl dismiss -a";
        "${modifier}+l" = "exec ~/.local/bin/lockscreen --force";
        "Ctrl+grave" = "exec clipman pick --max-items=25 --tool=CUSTOM --tool-args=\"${menu} -d -p 'Clipboard:'\"";
        "Ctrl+asciitilde" = "exec clipman clear --max-items=25 --tool=CUSTOM --tool-args=\"${menu} -d -p 'Delete from Clipboard:'\"";
        "XF86PowerOff" = "exec systemctl suspend";
        "XF86Sleep" = "exec systemctl suspend";
        "XF86AudioRaiseVolume" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+ && printf '%.0f\\n' $(echo \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[\\.0-9]\\+')*100\" | bc) > $wobsock";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%- && printf '%.0f\\n' $(echo \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[\\.0-9]\\+')*100\" | bc) > $wobsock";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && (wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -qi MUTED && echo 0 > $wobsock) || printf '%.0f\\n' $(echo \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[\\.0-9]\\+')*100\" | bc) > $wobsock";
        "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        "XF86MonBrightnessUp" = "exec brightnessctl set -m +10% | cut -d',' -f4 | rg -o '[0-9]+' > $wobsock";
        "XF86MonBrightnessDown" = "exec brightnessctl set -m 10%- | cut -d',' -f4 | rg -o '[0-9]+' > $wobsock";
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
      };
    };
    extraConfig = "default_border none";
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = "000000";
      daemonize = true;
    };
  };
  #programs.swayidle.enable = true;
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };
  programs.waybar = {
    enable = true;
    settings = {
      primary = {
        position = "left";
        spacing = 4;
        modules-right = ["sway/mode" "sway/workspaces"];
        modules-center = ["tray"];
        modules-left = ["clock" "battery" "network" "wireplumber" "custom/dwt"];
        "sway/mode" = {
          format = "<span style=\"italic\">{}</span>";
        };
        tray = {
          spacing = 10;
        };
        clock = {
          timezone = "America/New_York";
          format = ''
            {:%I
            %M
            
            %b
            %d}'';
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
          format-alt = "{:%Y-%m-%d}";
        };
        battery = {
          states = {
            good = 85;
            warning = 30;
            critical = 15;
          };
          format = ''
            {capacity}
            <big>{icon}</big>'';
          format-charging = ''
            {capacity}
            󰂄'';
          format-plugged = ''
            {capacity}
            󱐥'';
          format-alt = ''
            {time}
            {icon}'';
          format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
        };
        network = {
          format-wifi = ''
            {signalStrength}
            󰖩'';
          format-ethernet = "";
          tooltip-format = "{essid} {ifname} {ipaddr}";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "󰖪";
          format-alt = ''
            {essid}
            {ifname}
            {ipaddr}/{cidr}'';
        };
        wireplumber = {
          format = ''
            {volume}
            <big>{icon}</big>'';
          format-muted = "<big>󰸈</big>";
          format-icons = ["󰕿" "󰖀" "󰕾"];
          on-click = "pavucontrol";
        };
        "custom/dwt" = {
          exec = "~/.local/bin/touchpad.py waybar";
          on-click = "~/.local/bin/touchpad.py toggle";
          restart-interval = 2;
        };
      };
    };
    style = ./configs/waybar.css;
  };

  services.mako = {
    enable = true;
    anchor = "bottom-right";
  };
  # services.clipman.enable = true;

  xdg.configFile."fuzzel.ini" = {
    enable = true;
    source = ./configs/fuzzel.ini;
    target = "fuzzel/fuzzel.ini";
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
    MOZ_ENABLE_WAYLAND = 1;
    XDG_CURRENT_DESKTOP = "sway";
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
        Unit = "cleanage.service";
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
