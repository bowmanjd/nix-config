return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		event = "VeryLazy",
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-lua/plenary.nvim" },
		},
		cmd = {
			"CopilotChat",
			"CopilotChatOpen",
			"CopilotChatAgents",
			"CopilotChatModels",
			"CopilotChatExplain",
			"CopilotChatToggle",
		},
		keys = {
			{
				"<leader>co",
				"<Cmd>CopilotChatToggle<cr>",
				mode = { "n", "v" },
				desc = "LLM Chat using Github Copilot",
			},
		},
		-- build = "make tiktoken", -- Only on MacOS or Linux
		opts = {
			model = "gpt-4.1",
		},
	},

	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		cmd = {
			"CodeCompanion",
			"CodeCompanionChat",
			"CodeCompanionActions",
			"CodeCompanionCmd",
		},
		keys = {
			{
				"<leader>cc",
				"<Cmd>CodeCompanionChat<cr>",
				mode = { "n", "v" },
				desc = "LLM Chat using CodeCompanion",
			},
		},
		opts = {
			adapters = {
				claude_copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						name = "claude_copilot", -- Unique adapter name
						schema = {
							model = {
								default = "gpt-4.1",
							},
						},
					})
				end,
				openrouter = function()
					return require("codecompanion.adapters").extend("openai_compatible", {
						env = {
							url = "https://openrouter.ai/api",
							api_key = "OPENROUTER_API_KEY",
							chat_url = "/v1/chat/completions",
						},
						schema = {
							model = {
								default = "google/gemini-2.5-pro-preview-03-25",
							},
						},
					})
				end,
			},
			strategies = {
				chat = { adapter = "claude_copilot" },
				inline = { adapter = "claude_copilot" },
			},
		},
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
		keys = {
			{
				"<leader>ae",
				"<Cmd>AvanteClear<cr>",
				mode = "n",
				desc = "Clear Avante chat history",
			},
		},
		opts = {
			provider = "copilot",
			auto_suggestions_provider = nil, -- Set to nil to disable auto suggestions
			copilot = {
				model = "gpt-4.1",
				max_tokens = 90000,
			},
			suggestion = {
				enabled = false, -- Disable suggestions completely
				debounce = 2000,
				throttle = 2000,
			},
			vendors = {
				openrouter = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "google/gemini-2.5-pro-preview-03-25",
				},
			},
		},
		-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
		build = "make",
		-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
		dependencies = {
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below dependencies are optional,
			"echasnovski/mini.pick", -- for file_selector provider mini.pick
			"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
			"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
			"ibhagwan/fzf-lua", -- for file_selector provider fzf
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"zbirenbaum/copilot.lua", -- for providers='copilot'
			{
				-- support for image pasting
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					-- recommended settings
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						-- required for Windows users
						use_absolute_path = true,
					},
				},
			},
			{
				-- Make sure to set this up properly if you have lazy=true
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
}
