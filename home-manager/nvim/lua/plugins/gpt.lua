return {
	{
		"jackMort/ChatGPT.nvim",
		event = "VeryLazy",
		opts = {
			--api_key_cmd = "agegent " .. home .. "/.local/share/secrets/openai.enc.txt",
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
			"folke/trouble.nvim",
			"nvim-telescope/telescope.nvim",
		},
	},
}
