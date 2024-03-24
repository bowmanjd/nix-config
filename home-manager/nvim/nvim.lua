vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.hidden = true
vim.opt.mouse = "a"

vim.opt.fileformat = "unix"
vim.opt.fileformats = { "unix", "dos" }

vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.hlsearch = false
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.background = "dark"
vim.opt.termguicolors = true

vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_execute_on_save = 0

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "*.md" },
	callback = function()
		vim.opt.spell = true
		vim.opt.spelllang = "en_us"
		vim.opt.filetype = "markdown"
		vim.opt.formatoptions = "l"
		vim.opt.linebreak = true
		vim.opt.wrap = true
		vim.opt.textwidth = 0
		vim.opt.wrapmargin = 0
		vim.opt.list = false
	end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "ssh_config", "*/.ssh/config.d/*" },
	callback = function()
		vim.opt.filetype = "sshconfig"
	end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "*.sql" },
	callback = function()
		vim.opt.shiftwidth = 4
		vim.opt.tabstop = 4
		vim.opt.expandtab = true
		vim.opt.fileformat = "unix"
	end,
})

vim.notify = require("notify")

explain = function(content, duration)
  duration = duration or 1000
  vim.notify(content, "info", { timeout = duration, render = "minimal" })
end

require("nvim-treesitter.configs").setup({
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
})

require("catppuccin").setup({
	flavour = "mocha",
	color_overrides = {
		mocha = {
			base = "#000000",
			mantle = "#000000",
			crust = "#000000",
		},
	},
})
vim.cmd([[colorscheme catppuccin]])

require("lualine").setup({
	tabline = {
		lualine_a = {
			{
				"buffers",
			},
		},
	},
})

require("copilot").setup({
	suggestion = { enabled = false },
	panel = { enabled = false },
})

require("copilot_cmp").setup()

require("ibl").setup()
require("telescope").setup({
	extensions = {
		fzf = {
			fuzzy = true, -- false will only do exact matching
			override_generic_sorter = true, -- override the generic sorter
			override_file_sorter = true, -- override the file sorter
			case_mode = "smart_case", -- or "ignore_case" or "respect_case"
		},
	},
})
require("telescope").load_extension("fzf")
require("gitsigns").setup()

local cmp = require("cmp")
cmp.setup({
	view = {
		entries = "native",
	},
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<Tab>"] = function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			else
				fallback()
			end
		end,
	}),
	sources = cmp.config.sources({
		{ name = "copilot" },
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	}, {
		{ name = "buffer" },
	}),
})

cmp.setup.filetype("sql", {
	view = {
		entries = "native",
	},
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({ { name = "vim-dadbod-completion" }, { name = "luasnip" } }, { { name = "buffer" } }),
})

local on_attach = function(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end
	local function buf_set_option(...)
		vim.api.nvim_buf_set_option(bufnr, ...)
	end
	local opts = { noremap = true, silent = true }
	if client.supports_method("textDocument/formatting") then
		buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", opts)
	end
	buf_set_keymap("n", "<space>]", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
end

-- Setup lspconfig.
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local lspconfig = require("lspconfig")
local capabilities = cmp_nvim_lsp.default_capabilities()

lspconfig.bashls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})
lspconfig.pyright.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})
lspconfig.gopls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
			gofumpt = true,
		},
	},
})
lspconfig.golangci_lint_ls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})
lspconfig.rust_analyzer.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = {
		checkOnSave = {
			command = "clippy",
		},
	},
})
lspconfig.jsonls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})
lspconfig.html.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})
lspconfig.yamlls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})
lspconfig.dockerls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})
lspconfig.quick_lint_js.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

local lspkind = require("lspkind")
cmp.setup({
	formatting = {
		format = lspkind.cmp_format({
      mode = "symbol_text",
      max_width = 50,
      symbol_map = { Copilot = "" }
		}),
	},
})

vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })

local nullls = require("null-ls")
home = os.getenv("HOME")
nullls.setup({
	on_attach = on_attach,
	sources = {
		-- nullls.builtins.formatting.sqlformat.with({ args = { "-s", "4", "-m", "150", "-d", "    " } }),
		-- nullls.builtins.formatting.dprint.with({ filetypes = { "markdown", "toml" } }),
		nullls.builtins.formatting.sqlfluff.with({
			timeout_ms = 60000,
			extra_args = {
				"--config",
				home .. "/devel/sql/.sqlfluff",
				"--dialect",
				"tsql",
			},
		}),
		nullls.builtins.diagnostics.sqlfluff.with({
			timeout_ms = 60000,
			extra_args = {
				"--config",
				home .. "/devel/sql/.sqlfluff",
				"--dialect",
				"tsql",
			},
		}),
		nullls.builtins.formatting.prettierd.with({ filetypes = { "css", "scss" } }),
		nullls.builtins.diagnostics.stylelint,
		nullls.builtins.formatting.stylua,
		-- nullls.builtins.formatting.reorder_python_imports,
		nullls.builtins.formatting.black,
		--nullls.builtins.diagnostics.flake8,
		-- nullls.builtins.diagnostics.eslint_d,
		-- nullls.builtins.formatting.eslint_d,
		-- nullls.builtins.code_actions.eslint_d,
	},
})
