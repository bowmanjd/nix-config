{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    calibre
    chromium
    #easyeffects
    gimp
    helvum
    imv
    inkscape
    #libreoffice-fresh
    openttd
    pavucontrol
    prismlauncher
    vlc
    vscode-fhs
    xdotool
    xorg.xeyes
    ydotool
  ];

  programs.firefox = {
    enable = true;
    #package = (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true;}) {});
    #package = pkgs.firefox-wayland.override { pipewireSupport = true;};
  };
}

