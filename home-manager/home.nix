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

  home = {
    username = "bowmanjd";
    homeDirectory = "/home/bowmanjd";
  };

  programs.bash = {
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
    '';
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

  home.file."secrets" = {
    enable = true;
    recursive = true;
    source = ./secrets;
    target = ".ssh/secrets";
  };

  home.sessionVariables = {
    EMAIL = "git@bowmanjd.com";
  };
}
