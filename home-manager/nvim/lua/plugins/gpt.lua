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
			model = "gpt-5-mini",
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
				gpt5mini_copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						name = "gpt5mini_copilot", -- Unique adapter name
						schema = {
							model = {
								default = "gpt-5-mini",
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
								default = "qwen/qwen3-coder",
							},
						},
					})
				end,
			},
			strategies = {
				chat = { adapter = "gpt5mini_copilot" },
				inline = { adapter = "copilot" },
			},
		},
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false,
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
			suggestion = {
				enabled = false, -- Disable suggestions completely
				debounce = 2000,
				throttle = 2000,
			},
			providers = {
				copilot = {
					model = "gpt-5-mini",
					extra_request_body = {
						max_tokens = 128000,
					},
				},
				openrouter = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "google/gemini-2.5-pro-preview-03-25",
				},
			},
		},
		build = function()
			-- conditionally use the correct build system for the current OS
			if vim.fn.has("win32") == 1 then
				return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
			else
				return "make"
			end
		end,
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
