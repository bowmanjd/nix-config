return {
	"stevearc/conform.nvim",
  name = "conform",
  event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
      function() 
        require'conform'.format
      end,
      mode = { "n", "v" },
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
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
