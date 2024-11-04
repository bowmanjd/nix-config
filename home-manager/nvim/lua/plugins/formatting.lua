return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			-- Customize or remove this keymap to your liking
			"<leader>f",
			function()
				require("conform").format({ async = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	-- This will provide type hinting with LuaLS
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		formatters_by_ft = {
			css = { "stylelint" },
			lua = { "stylua" },
			nix = { "alejandra" },
			python = { "isort", "black" },
			rust = { "rustfmt" },
			-- You can customize some of the format options for the filetype (:help conform.format)
			-- Conform will run the first available formatter
			javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
			sql = { "sqlfluff" },
		},
		default_format_opts = {
			async = true,
			lsp_format = "fallback",
			timeout_ms = 60000,
		},
		formatters = {
			sqlfluff = {
				require_cwd = false,
				quiet = true,
				exit_codes = { 0, 1 },
				args = {
					"fix",
					"--ignore-local-config",
					"--dialect",
					"tsql",
					"--config",
					home .. "/devel/sql/.sqlfluff",
					"-",
				},
			},
		},
	},
	init = function()
		-- If you want the formatexpr, here is the place to set it
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
