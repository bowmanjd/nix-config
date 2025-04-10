return {
	{
		"nmac427/guess-indent.nvim",
		config = true,
	},
	{ "akinsho/toggleterm.nvim", version = "*", config = true },
	{ "echasnovski/mini.surround", version = "*", config = true },
	{ "numToStr/Comment.nvim", version = "*", config = true },
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {},
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
	},
	{
		"nvim-telescope/telescope.nvim",
		-- branch = "0.1.x",
		opts = {
			extensions = {
				fzf = {
					fuzzy = true, -- false will only do exact matching
					override_generic_sorter = true, -- override the generic sorter
					override_file_sorter = true, -- override the file sorter
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
				},
				["ui-select"] = {
					require("telescope.themes").get_dropdown(),
				},
			},
		},
		config = function(_, opts)
			local tele = require("telescope")
			tele.setup(opts)
			tele.load_extension("fzf")
			tele.load_extension("ui-select")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

			-- CargasEnergy
			vim.keymap.set("n", "<leader>sc", function()
				builtin.live_grep({
					--cwd = "~/devel/CargasEnergy/CargasEnergyDB/Schema Objects/Schemas/",
					cwd = (vim.fn.isdirectory("CargasEnergyDB") > 0 and "" or "~/devel/CargasEnergy/")
						.. "CargasEnergyDB/Schema Objects/Schemas/",
					glob_pattern = { "**/Tables/**", "!**/{Indexes,Keys,Triggers,Constraints}/**" },
					path_display = { "filename_first" },
					additional_args = { "-i" },
				})
			end, {
				desc = "[S]earch for [C]olumn",
			})
			vim.keymap.set("n", "<leader>st", function()
				builtin.find_files({
					cwd = (vim.fn.isdirectory("CargasEnergyDB") > 0 and "" or "~/devel/CargasEnergy/")
						.. "CargasEnergyDB/Schema Objects/Schemas/",
					find_command = {
						"fd",
						"-i",
						"--type",
						"f",
						"--color",
						"never",
						"-E",
						"**/{Views,Programmability,Indexes,Keys,Triggers,Constraints}/**",
						"--full-path",
						"-g",
						"**/Tables/**",
					},
					path_display = { "filename_first" },
				})
			end, {
				desc = "[S]earch for [T]ables",
			})
			vim.keymap.set("n", "<leader>sp", function()
				builtin.find_files({
					--cwd = "~/devel/CargasEnergy/CargasEnergyDB/Schema Objects/Schemas/",
					cwd = (vim.fn.isdirectory("CargasEnergyDB") > 0 and "" or "~/devel/CargasEnergy/")
						.. "CargasEnergyDB/Schema Objects/Schemas/",
					search_dirs = {
						"CRM/Programmability/",
						"API/Programmability/",
						"diagnostic/Programmability/",
						"Integration/Programmability/",
						"mdo/Programmability/",
						"dbo/Programmability/",
						"DataConversion/Programmability/",
						"Dashboard/Programmability/",
					},
					path_display = { "filename_first" },
				})
			end, {
				desc = "[S]earch for [P]rograms",
			})
			vim.keymap.set("n", "<leader>si", function()
				builtin.live_grep({
					cwd = (vim.fn.isdirectory("CargasEnergyDB") > 0 and "." or "~/devel/CargasEnergy/"),
					glob_pattern = {
						"**/Programmability/**",
						"*.js",
						"*.jsx",
						"*.cs",
						"*.aspx",
					},
					path_display = { "filename_first" },
					additional_args = { "-i" },
				})
			end, {
				desc = "[S]earch [In] Programs",
			})

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
	},
}
