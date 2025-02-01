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

vim.opt.rtp:append(treesitterPath)
vim.opt.rtp:append(treesitterGrammars)
package.cpath = package.cpath .. jsregexpPath
package.cpath = package.cpath .. tiktokenCorePath
