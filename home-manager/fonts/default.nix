{pkgs, ...}: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    fira-code
    fira-code-symbols
    font-awesome
    liberation_ttf
    maple-mono-NF
    mplus-outline-fonts.githubRelease
    nerd-fonts.hack
    nerd-fonts.noto
    nerd-fonts.arimo
    nerd-fonts.iosevka
    nerd-fonts.fira-code
    nerd-fonts.inconsolata
    nerd-fonts.sauce-code-pro
    nerd-fonts.caskaydia-cove
    noto-fonts
    noto-fonts-emoji
    proggyfonts
  ];
}
