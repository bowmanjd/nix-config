# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  # TODO: Set your username
  home = {
    username = "bowmanjd";
    homeDirectory = "/home/bowmanjd";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [
		bat
		bemenu
		calibre
		eza
		foot
		fzf
		gimp
		inkscape
		nerdfonts
		prismlauncher
		libreoffice-fresh
		qrencode
		wl-clipboard
		wob
	];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;
	programs.firefox = {
		enable = true;
		package = "firefox-wayland";
	}

	wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      # Use kitty as default terminal
      terminal = "foot"; 
      startup = [
        # Launch Firefox on start
        {command = "wl-paste -t text --watch clipman store --max-items=500";}
      ];
			bars = [ {
				command = "waybar";
			} ];
			input = {
				"1739:52710:DLL0945:00_06CB:CDE6_Touchpad" = {
          dwt = "enabled";
          tap = "enabled";
          middle_emulation = "enabled";
				};
			};
			menu = "bemenu-run -p 'Run:' -n --fn 'Hack Nerd Font 15' -i --no-exec | xargs swaymsg exec --";
			keybindings = {
				let mod = config.wayland.windowManager.sway.config.modifier;
				let term = config.wayland.windowManager.sway.config.terminal;
				in {
					"${modifier}+Shift+w" = "exec firefox";
				}
			};
    };
  };

  programs.swaylock.enable = true;
  programs.swayidle.enable = true;

	services.mako = {
		enable = true;
		anchor = "bottom-right";
	}
	services.clipman.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
