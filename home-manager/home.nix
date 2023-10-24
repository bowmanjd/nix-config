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
		cargo
		clipman
		degit
		dockerfile-language-server-nodejs
		dprint
		du-dust
		easyeffects
		eslint_d
		eza
		ffmpeg_6-full
		foot
		fuzzel
		fzf
		gimp
		glow
		go
		helvum
		htop
		inkscape
		jq
		jql
		libgourou
		libreoffice-fresh
		microsoft-edge
		neofetch
		nerdfonts
		nmap
		nodePackages_latest.bash-language-server
		nodePackages_latest.poor-mans-t-sql-formatter-cli
		nodePackages_latest.prettier
		nodePackages_latest.pyright
		openttd
		p7zip
		pinentry
		podman
		prettierd
		prismlauncher
		(python311.withPackages(ps: with ps; [
			bandit
			beautifulsoup4
			black
			eradicate
			flake8
			flake8-bugbear
			flake8-docstrings
			fonttools
			isort
			lxml
			pep8-naming
			pexpect
			ptpython
			pynvim
			pytest
			reorder-python-imports
			types-beautifulsoup4
			wheel
		]))
		qrencode
		quick-lint-js
		rage
		rustc
		skopeo
		sqlfluff
		starship
		stylelint
		stylua
		unixODBCDrivers.msodbcsql18
		vhs
		virtualenv
		visidata
		vscode-langservers-extracted
		waybar
		wl-clipboard
		wob
		yaml-language-server
		yt-dlp
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
		enableCompletion = true;
		enableVteIntegration = true;
		historyControl = ["erasedups" "ignoredups" "ignorespace"];
	};
	programs.direnv = {
		enable = true;
		enableBashIntegration = true;
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
			csv-vim
			direnv-vim
			{
				plugin = catppuccin-nvim;
				config = ''
					require("catppuccin").setup({
						flavour = "mocha",
						color_overrides = {
							mocha = {
								base = "#000000",
								mantle = "#000000",
								crust = "#000000",
							},
						},
					})
					vim.opt.termguicolors = true
					vim.cmd([[colorscheme catppuccin]])'';
			}
			{
				plugin = lualine-nvim;
				config = ''
					require('lualine').setup(
						tabline = {
							lualine_a = {
								{
									"buffers",
								},
							},
						},
					)'';
			}
			{
				plugin = indent-blankline-nvim;
				config = "require('ibl').setup()";
			}
			cmp-buffer
			cmp_luasnip
			cmp-nvim-lsp
			gitsigns-nvim
			luasnip
			null-ls-nvim
			nvim-cmp
			nvim-lightbulb
      nvim-lspconfig
      {
				plugin = nvim-treesitter.withAllGrammars;
				config = ''
					require'nvim-treesitter.configs'.setup {
						ensure_installed = {
							"all"
						},
						highlight = {
							enable = true,
							additional_vim_regex_highlighting = false,
						},
					}'';
			}
			nvim-web-devicons
      plenary-nvim
			telescope-nvim
			telescope-fzf-native-nvim
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      #mini-nvim
    ];
		extraLuaConfig = ''
			vim.g.mapleader = " "
			vim.g.maplocalleader = " "
			vim.opt.hidden = true
			vim.opt.mouse = "a"

			vim.opt.fileformat = "unix"
			vim.opt.fileformats = { "unix", "dos" }

			vim.opt.backup = false
			vim.opt.writebackup = false

			vim.opt.smartindent = true
			vim.opt.tabstop = 2
			vim.opt.softtabstop = 2
			vim.opt.shiftwidth = 2

			vim.opt.number = true
			vim.opt.cursorline = true
			vim.opt.clipboard = "unnamedplus"
			vim.opt.hlsearch = false
			vim.opt.ignorecase = true
			vim.opt.smartcase = true

			vim.opt.background = "dark"
			vim.opt.termguicolors = true

			vim.cmd(
				"au BufNewFile,BufRead *.md set spell spelllang=en_us ft=markdown formatoptions=l lbr wrap textwidth=0 wrapmargin=0 nolist"
			)
			vim.cmd("au BufNewFile,BufRead ssh_config,*/.ssh/config.d/*  setf sshconfig")
			vim.cmd("au BufNewFile,BufRead *.sql set shiftwidth=4 tabstop=4 expandtab ff=unix")
			vim.cmd("au BufNewFile,BufRead *.js set shiftwidth=2 tabstop=2 expandtab")'';
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

  programs.swaylock = {
		enable = true;
		settings = {
			color = "000000";
			daemonize = true;
		};
	};
  programs.swayidle.enable = true;
  programs.starship = {
		enable = true;
		enableBashIntegration = true;
	};
	programs.waybar = {
		enable = true;
		settings = {
			primary = {
				position = "left";
				spacing = 4;
				modules-right = ["sway/mode" "sway/workspaces"];
				modules-center = ["tray"];
				modules-left = ["clock" "battery" "network" "wireplumber" "custom/dwt"];
				"sway/mode" = {
						format = "<span style=\"italic\">{}</span>";
				};
				tray = {
						spacing = 10;
				};
				clock = {
						timezone = "America/New_York";
						format = ''
							{:%I
							%M
							
							%b
							%d}'';
						tooltip-format = ''
							<big>{:%Y %B}</big>
							<tt><small>{calendar}</small></tt>'';
						format-alt = "{:%Y-%m-%d}";
				};
				battery = {
						states = {
								good = 85;
								warning = 30;
								critical = 15;
						};
						format = ''
							{capacity}
							<big>{icon}</big>'';
						format-charging = ''
							{capacity}
							'';
						format-plugged = ''
							{capacity}
							ﮣ'';
						format-alt = ''
							{time}
							{icon}'';
						format-icons = ["" "" "" "" "" "" "" "" "" ""];
				};
				network = {
						format-wifi = ''
							{signalStrength}
							直'';
						format-ethernet = "";
						tooltip-format = "{essid} {ifname} {ipaddr}";
						format-linked = "{ifname} (No IP) ";
						format-disconnected = "睊";
						format-alt = ''
							{essid}
							{ifname}
							{ipaddr}/{cidr}'';
				};
				wireplumber = {
						format = ''
							{volume}
							<big>{icon}</big>'';
						format-muted = "<big>婢</big>";
						format-icons = ["奄" "奔" "墳"];
						on-click = "pavucontrol";
				};
				"custom/dwt" = {
					exec = "~/.local/bin/touchpad.py waybar";
					on-click = "~/.local/bin/touchpad.py toggle";
					restart-interval = 2;
				};
			};
		};
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

	home.sessionPath = [
  "$HOME/.local/bin"
	];
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
