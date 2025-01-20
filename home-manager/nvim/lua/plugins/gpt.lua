return {
	{
		"jackMort/ChatGPT.nvim",
		event = "VeryLazy",
		opts = {
			api_key_cmd = "agegent " .. home .. "/.ssh/secrets/openai.enc.txt",
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
			"folke/trouble.nvim",
			"nvim-telescope/telescope.nvim",
		},
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-lua/plenary.nvim" },
		},
		-- build = "make tiktoken", -- Only on MacOS or Linux
		opts = {
			model = "claude-3.5-sonnet",
		},
	},
}
