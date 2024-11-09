return {
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {},
	},
	{
		"nvim-telescope/telescope.nvim",
    branch = '0.1.x',
		opts = {
			extensions = {
				fzf = {
					fuzzy = true, -- false will only do exact matching
					override_generic_sorter = true, -- override the generic sorter
					override_file_sorter = true, -- override the file sorter
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
				},
			},
		},
		config = function(_, opts)
			local tele = require("telescope")
			tele.setup(opts)
			tele.load_extension("fzf")
		end,
		dependencies = { "nvim-telescope/telescope-fzf-native.nvim", "nvim-lua/plenary.nvim" },
	},
}
