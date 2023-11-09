{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    calibre
    easyeffects
    gimp
    helvum
    inkscape
    libreoffice-fresh
    microsoft-edge
    openttd
    pavucontrol
    prismlauncher
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
  };
}

