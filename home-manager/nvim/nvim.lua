require("base")

require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
}, {
	performance = {
		reset_packpath = false,
		rtp = {
			reset = false,
		},
	},
	dev = {
		path = pluginPath,
		patterns = { "" },
		fallback = false,
	},
	install = {
		-- Safeguard in case we forget to install a plugin with Nix
		missing = false,
	},
})
