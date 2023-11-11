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

  programs.git = {
    userEmail = "jbowman@cargas.com";
    extraConfig = {
      user.signingKey = builtins.readFile ./worksecrets/id_ed25519.pub;
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
