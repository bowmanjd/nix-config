return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{
				"<leader>l",
				function()
					require("lint").try_lint()
				end,
				desc = "Lint buffer",
			},
			{
				"<leader>L",
				function()
					vim.diagnostic.enable(not vim.diagnostic.is_enabled())
				end,
				desc = "Lint buffer",
			},
		},
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = lint.linters_by_ft or {}
			lint.linters_by_ft["markdown"] = { "markdownlint" }
			lint.linters_by_ft["sql"] = { "sqlfluff" }
			lint.linters_by_ft["javascriptreact"] = { "eslint" }
			lint.linters_by_ft["javascript"] = { "biomejs" }
			lint.linters_by_ft["typescript"] = { "biomejs" }

			lint.linters.sqlfluff.stdin = true
			lint.linters.sqlfluff.args = {
				"lint",
				"--format=json",
				--"--ignore-local-config",
				"--dialect",
				function()
					-- This function is evaluated each time lint runs
					local d = vim.b.sql_dialect or "tsql"
					for i = 1, math.min(20, vim.fn.line("$")) do
						local line = vim.fn.getline(i)
						local found = line:match("%-%-%s*dialect:%s*(%w+)")
						if found then
							d = found
							break
						end
					end
					return d
				end,
				"--config",
				home .. "/devel/sql/.sqlfluff",
				"-",
			}

			-- Create autocommand which carries out the actual linting
			-- on the specified events.
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					-- Only run the linter in buffers that you can modify in order to
					-- avoid superfluous noise, notably within the handy LSP pop-ups that
					-- describe the hovered symbol using Markdown.
					if vim.opt_local.modifiable:get() then
						lint.try_lint()
					end
				end,
			})
		end,
	},
}
