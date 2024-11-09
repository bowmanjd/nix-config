{
  pkgs,
  ...
}: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    fira-code
    fira-code-symbols
    font-awesome
    liberation_ttf
    maple-mono-NF
    mplus-outline-fonts.githubRelease
    nerdfonts
    noto-fonts
    noto-fonts-emoji
    proggyfonts
  ];
}

