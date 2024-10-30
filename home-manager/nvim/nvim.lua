home = os.getenv("HOME")

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
vim.opt.signcolumn = "yes"

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

notify = require("notify")
render_explain = function(bufnr, notif, highlights, config)
	local max_message_width = math.max(math.max(unpack(vim.tbl_map(function(line)
		return vim.fn.strchars(line)
	end, notif.message))))
	local title = notif.title[1]
	local title_accum = vim.str_utfindex(title)

	local namespace = require("notify.render.base").namespace()

	vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { "", "" })
	vim.api.nvim_buf_set_extmark(bufnr, namespace, 0, 0, {
		virt_text = {
			{ title, highlights.title },
		},
		virt_text_win_col = 0,
		priority = 10,
	})
	vim.api.nvim_buf_set_extmark(bufnr, namespace, 1, 0, {
		virt_text = {
			{
				string.rep("━", math.max(max_message_width, title_accum, config.minimum_width())),
				highlights.border,
			},
		},
		virt_text_win_col = 0,
		priority = 10,
	})
	vim.api.nvim_buf_set_lines(bufnr, 2, -1, false, notif.message)

	vim.api.nvim_buf_set_extmark(bufnr, namespace, 2, 0, {
		hl_group = highlights.body,
		end_line = 1 + #notif.message,
		end_col = #notif.message[#notif.message],
		priority = 50,
	})
end

notify.setup({
	minimum_width = 20,
	timeout = 1000,
})

vim.notify = notify

explain = function(content, title, duration)
	duration = duration or 1000
	vim.notify(content, "info", { title = title, timeout = duration, render = render_explain })
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

require("gitsigns").setup({
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navigation
		map("n", "]c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gitsigns.nav_hunk("next")
			end
		end)

		map("n", "[c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gitsigns.nav_hunk("prev")
			end
		end)

		-- Actions
		map("n", "<leader>hs", gitsigns.stage_hunk)
		map("n", "<leader>hr", gitsigns.reset_hunk)
		map("v", "<leader>hs", function()
			gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end)
		map("v", "<leader>hr", function()
			gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end)
		map("n", "<leader>hS", gitsigns.stage_buffer)
		map("n", "<leader>hu", gitsigns.undo_stage_hunk)
		map("n", "<leader>hR", gitsigns.reset_buffer)
		map("n", "<leader>hp", gitsigns.preview_hunk)
		map("n", "<leader>hb", function()
			gitsigns.blame_line({ full = true })
		end)
		map("n", "<leader>tb", gitsigns.toggle_current_line_blame)
		map("n", "<leader>hd", gitsigns.diffthis)
		map("n", "<leader>hD", function()
			gitsigns.diffthis("~")
		end)
		map("n", "<leader>td", gitsigns.toggle_deleted)

		-- Text object
		map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
	end,
})

require("chatgpt").setup({
	api_key_cmd = "agegent " .. home .. "/.local/share/secrets/openai.enc.txt",
})

require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "powershell_es" },
})

local lspconfig_defaults = require("lspconfig").util.default_config
lspconfig_defaults.capabilities =
	vim.tbl_deep_extend("force", lspconfig_defaults.capabilities, require("cmp_nvim_lsp").default_capabilities())

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP actions",
	callback = function(event)
		local opts = { buffer = event.buf }

		vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
		vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
		vim.keymap.set("n", "<leader>]", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
		vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
		vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
		vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
		vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
		vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
		vim.keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
		vim.keymap.set({ "n", "x" }, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
		vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
	end,
})

require("luasnip.loaders.from_vscode").lazy_load()

local cmp = require("cmp")
local lspkind = require("lspkind")
local luasnip = require("luasnip")
cmp.setup({
	view = {
		entries = "native",
	},
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = {
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		["<CR>"] = cmp.mapping({
			i = function(fallback)
				if cmp.visible() and cmp.get_active_entry() then
					cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
				else
					fallback()
				end
			end,
			s = cmp.mapping.confirm({ select = true }),
			c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.locally_jumpable(1) then
				luasnip.jump(1)
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	},
	formatting = {
		format = lspkind.cmp_format({
			mode = "symbol_text",
			max_width = 50,
			symbol_map = {
				Copilot = "",
				Rg = "󰍉",
				Look = "👀",
				DB = "󰆼",
				VariableMember = "",
				Tmux = "",
			},
			before = function(entry, vim_item)
				vim_item.menu = ({
					["vim-dadbod-completion"] = "[DB]",
					buffer = "[Buffer]",
					copilot = "[Copilot]",
					emoji = "[Emoji]",
					look = "[Look]",
					luasnip = "[Snippet]",
					nvim_lsp = "[LSP]",
					path = "[Path]",
					rg = "[Rg]",
					tags = "[Tag]",
					tmux = "[Tmux]",
					treesitter = "[Treesitter]",
				})[entry.source.name]
				return vim_item
			end,
		}),
	},
	sources = cmp.config.sources({
		{ name = "copilot", group_index = 2 },
		{ name = "nvim_lsp", group_index = 2 },
		{ name = "vim-dadbod-completion", group_index = 2 },
		{ name = "luasnip", group_index = 2 },
		{ name = "treesitter", group_index = 2 },
		{
			name = "tmux",
			option = { all_panes = true },
			group_index = 2,
		},
		{
			name = "look",
			keyword_length = 3,
			group_index = 2,
			option = { loud = true, fflag = true, dict = home .. "/.config/look/words" },
		},
		{ name = "buffer", group_index = 2 },
		{ name = "tags", keyword_length = 2, group_index = 2 },
		{ name = "rg", keyword_length = 3, group_index = 2 },
		{ name = "path", group_index = 2 },
		{ name = "emoji", group_index = 2 },
	}),
})

vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })

local conform = require("conform")
conform.setup({
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
})

vim.keymap.set("n", "<leader>f", "<cmd>lua require'conform'.format()<CR>", { noremap = true })

local lint = require("lint")
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

lint.linters_by_ft = {
	sql = { "sqlfluff" },
	javascript = { "biomejs" },
}

vim.keymap.set("n", "<leader>l", "<cmd>lua require'lint'.try_lint()<CR>", { noremap = true })
vim.keymap.set("n", "<leader>L", "<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<CR>", { noremap = true })

-- Setup lspconfig.
local lspconfig = require("lspconfig")

lspconfig.bashls.setup({})
lspconfig.biome.setup({})
lspconfig.powershell_es.setup({
	bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
})
lspconfig.emmet_language_server.setup({})
lspconfig.pyright.setup({})
lspconfig.gopls.setup({
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
lspconfig.golangci_lint_ls.setup({})
lspconfig.rust_analyzer.setup({
	settings = {
		checkOnSave = {
			command = "clippy",
		},
	},
})
lspconfig.jsonls.setup({})
lspconfig.html.setup({})
lspconfig.yamlls.setup({})
lspconfig.dockerls.setup({})
lspconfig.quick_lint_js.setup({})
