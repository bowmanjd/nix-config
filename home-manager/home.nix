{
  pkgs,
  lib,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    ./base
    ./nvim
    (import ./llm {
      inherit pkgs lib;
      environment = "home";
    })
    ./fonts
    ./sway
    ./guiapps
  ];

  home.packages = with pkgs; [
    android-tools
    google-cloud-sdk
    #wrangler
  ];

  home = {
    username = "bowmanjd";
    homeDirectory = "/home/bowmanjd";
  };

  programs.git = {
    userEmail = "git@bowmanjd.com";
    extraConfig = {
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

  programs.ssh.matchBlocks = {
    "work" = {
      hostname = "10.15.8.14";
      user = "jbowman";
      port = 5788;
    };
    "workwsl" = {
      hostname = "10.15.8.14";
      user = "jbowman";
      port = 5517;
      extraOptions = {
        RequestTTY = "force";
        PubkeyAuthentication = "no";
        PreferredAuthentications = "password";
        RemoteCommand = "\"C:\\Program Files\\WSL\\wsl.exe\" --cd ~";
      };
    };
    "workps" = {
      hostname = "10.15.8.14";
      user = "jbowman@cargas";
      port = 5517;
      extraOptions = {
        RequestTTY = "force";
        RemoteCommand = "pwsh -NoProfile";
      };
    };
    "workpw" = {
      hostname = "10.15.8.14";
      user = "jbowman";
      port = 5517;
      extraOptions = {
        RequestTTY = "force";
        RemoteCommand = "pwsh -NoProfile";
        PubkeyAuthentication = "no";
        PreferredAuthentications = "password";
      };
    };
  };

  xdg.configFile."yt-dlp.conf" = {
    enable = true;
    source = ./yt-dlp-home.conf;
    target = "yt-dlp/config";
  };
}
