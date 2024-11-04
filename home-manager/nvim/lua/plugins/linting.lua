return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = lint.linters_by_ft or {}
			lint.linters_by_ft["markdown"] = { "markdownlint" }
			lint.linters_by_ft["sql"] = { "sqlfluff" }
			lint.linters_by_ft["javascript"] = { "biomejs" }

			lint.linters.sqlfluff.stdin = true
			lint.linters.sqlfluff.args = {
				"lint",
				"--format=json",
				"--ignore-local-config",
				"--dialect",
				"tsql",
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
		init = function()
			vim.keymap.set("n", "<leader>l", "<cmd>lua require'lint'.try_lint()<CR>", { noremap = true })
			vim.keymap.set("n", "<leader>L", "<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<CR>", { noremap = true })
		end,
	},
}
