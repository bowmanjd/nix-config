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
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "zbirenbaum/copilot.lua" }, -- or zbirenbaum/copilot.lua
			{ "nvim-lua/plenary.nvim" }, -- for curl, log and async functions
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		opts = {
			-- See Configuration section for options
			model = "claude-3.5-sonnet",
		},
		-- See Commands section for default commands if you want to lazy load on them
	},
}
