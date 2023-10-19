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
		brightnessctl
		buildah
		calibre
		clipman
		du-dust
		eza
		ffmpeg_6-full
		foot
		fuzzel
		fzf
		gimp
		htop
		inkscape
		jq
		jql
		libreoffice-fresh
		nerdfonts
		pinentry
		podman
		prismlauncher
		qrencode
		rage
		skopeo
		starship
		unixODBCDrivers.msodbcsql18
		wl-clipboard
		wob
	];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;
	programs.firefox = {
		enable = true;
		package = "firefox-wayland";
	};
	programs.bash = {
		enable = true;
	};
	programs.foot = {
		enable = true;
		settings = {
			main = {
				term = "xterm-256color";
				font = "Hack Nerd Font:size=14";
			};
		};
	};
	programs.eza = {
		enable = true;
		enableAliases = true;
		git = true;
		icons = true;
	};
	programs.neovim = {
		enable = true;
		defaultEditor = true;
		viAlias = true;
		vimAlias = true;
		vimdiffAlias = true;
		withNodeJs = true;
		withPython3 = true;
		plugins = with pkgs.vimPlugins; [
			cmp-buffer
			cmp-nvim-lsp
			csv-vim
			direnv-vim
			gitsigns-nvim
			indent-blankline-nvim
			lualine-nvim
			luasnip
			null-ls-nvim
			nvim-cmp
			nvim-lightbulb
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
			nvim-web-devicons
      plenary-nvim
			telescope-nvim
			telescope-fzf-native-nvim
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      #mini-nvim
    ];
	};

	wayland.windowManager.sway = {
    enable = true;
		extraConfigEarly = ''
		set $wobsock $XDG_RUNTIME_DIR/wob.sock
		'';
    config = rec {
      modifier = "Mod4";
      terminal = "foot"; 
      startup = [
        {command = "wl-paste -t text --watch clipman store --max-items=500";}
        {command = "~/.local/bin/idle";}
        {command = "rm -f $wobsock && mkfifo $wobsock && tail -f $wobsock | wob";}
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
			output = {
			};
			window = {
				border = 0;
				hideEdgeBorders = "both";
			};
			menu = "fuzzel -p 'Run:' --no-exit-on-keyboard-focus-loss -f 'Hack Nerd Font 15' --launch-prefix 'swaymsg exec --'";
			keybindings = {
				"${modifier}+Shift+w" = "exec firefox";
				"${modifier}+question" = "exec ~/.local/bin/bemoji -n";
				"Print" = "exec ~/.local/bin/screencap";
				"${modifier}+m" = "exec makoctl dismiss -a";
				"${modifier}+l" = "exec ~/.local/bin/lockscreen --force";
				"Ctrl+grave" =  "exec clipman pick --max-items=25 --tool=CUSTOM --tool-args=\"${menu} -d -p 'Clipboard:'\"";
				"Ctrl+asciitilde" = "exec clipman clear --max-items=25 --tool=CUSTOM --tool-args=\"${menu} -d -p 'Delete from Clipboard:'\"";
				"XF86PowerOff" =  "exec systemctl suspend";
				"XF86Sleep" = "exec systemctl suspend";
				"XF86AudioRaiseVolume" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+ && printf '%.0f\\n' $(echo \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[\\.0-9]\\+')*100\" | bc) > $wobsock";
				"XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%- && printf '%.0f\\n' $(echo \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[\\.0-9]\\+')*100\" | bc) > $wobsock";
				"XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && (wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -qi MUTED && echo 0 > $wobsock) || printf '%.0f\\n' $(echo \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[\\.0-9]\\+')*100\" | bc) > $wobsock";
				"XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
				"XF86MonBrightnessUp" = "exec brightnessctl set -m +10% | cut -d',' -f4 | rg -o '[0-9]+' > $wobsock";
				"XF86MonBrightnessDown" = "exec brightnessctl set -m 10%- | cut -d',' -f4 | rg -o '[0-9]+' > $wobsock";
			};
    };
  };

  programs.swaylock.enable = true;
  programs.swayidle.enable = true;
  programs.starship = {
		enable = true;
		enableBashIntegration = true;
	};

	services.mako = {
		enable = true;
		anchor = "bottom-right";
	};
	# services.clipman.enable = true;
	
	# copy files to ~/.local/bin

	xdg.configFile."scripts" = {
    enable = true;
		executable = true;
		recursive = true;
    source = ./scripts;
    target = "../bin";
  };

	home.sessionVariables = {
		MOZ_ENABLE_WAYLAND = 1;
		XDG_CURRENT_DESKTOP = "sway"; 
		EMAIL = "git@bowmanjd.com";
	};

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
