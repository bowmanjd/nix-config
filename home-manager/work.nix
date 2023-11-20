{
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    ./base
    ./nvim
  ];

  home = {
    username = "jbowman";
    homeDirectory = "/home/jbowman";
  };

  home.packages = with pkgs; [
    workscripts
  ];

  programs.git = {
    userEmail = "jbowman@cargas.com";
    extraConfig = {
      user.signingKey = builtins.readFile ./worksecrets/id_ed25519.pub;
    };
  };

  programs.bash = {
    bashrcExtra = ''
      PROMPT_COMMAND=''${PROMPT_COMMAND:+"$PROMPT_COMMAND; "}'printf "\e]9;9;%s\e\\" "$(wslpath -w "$PWD")"; printf "\033]0;$TITLE\a"'
      if [ ! -L "$HOME/.local/bin/win32yank" ]; then
        ln -s /mnt/c/Users/jbowman/scoop/shims/win32yank.exe "$HOME/.local/bin/win32yank"
      fi
      export SQLSERVER=127.0.0.1
      export SQLCMDUSER="sa"
      export SQLCMDDBNAME="CargasEnergy"
    '';
    shellAliases = {
      c = "win32yank -i";
      p = "win32yank -o";
    };
  };
  programs.ssh.matchBlocks = {
    "tun" = {
      hostname = "129.213.98.217";
      user = "jbowman";
      port = 5517;
    };
    "sqltun" = {
      hostname = "129.213.98.217";
      user = "tunnel";
      port = 5517;
      extraOptions = {
        RequestTTY = "no";
        ExitOnForwardFailure = "yes";
      };
    };
  };
  home.file."secrets" = {
    enable = true;
    recursive = true;
    source = ./worksecrets;
    target = ".ssh/secrets";
  };

  home.sessionVariables = {
    EMAIL = "jbowman@cargas.com";
  };
}
