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
    inkscape
    libreoffice-fresh
    microsoft-edge
    openttd
    pavucontrol
    prismlauncher
    xdotool
    xorg.xeyes
    ydotool
  ];

  programs.firefox = {
    enable = true;
    package = (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true;}) {});
    #package = pkgs.firefox-wayland.override { pipewireSupport = true;};
  };
}

