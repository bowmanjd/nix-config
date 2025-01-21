return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"octaltree/cmp-look",
			"hrsh7th/cmp-path",
			"lukas-reineke/cmp-rg",
			"hrsh7th/cmp-nvim-lsp",
			"onsails/lspkind.nvim",
			"L3MON4D3/LuaSnip",
			"ray-x/cmp-treesitter",
			"andersevenrud/cmp-tmux",
			"rafamadriz/friendly-snippets",
			"zbirenbaum/copilot-cmp",
			"zbirenbaum/copilot.lua",
			"windwp/nvim-autopairs",
		},
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/lua/snippets/" })

			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})

			require("copilot_cmp").setup()

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

			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

			vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
		end,
	},
}
