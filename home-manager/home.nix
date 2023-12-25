{
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    ./base
    ./nvim
    ./fonts
    ./sway
    ./guiapps
  ];

  home.packages = with pkgs; [
    android-tools 
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
}
