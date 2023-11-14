# build using 'nix build .#basescripts'
pkgs: {
  basescripts = pkgs.callPackage ./basescripts { };
}
