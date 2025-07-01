return {
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {},
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"Hoffs/omnisharp-extended-lsp.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function(_, opts)
			local lspconfig = require("lspconfig")

			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = { "powershell_es" },
			})

			local lspconfig_defaults = lspconfig.util.default_config
			lspconfig_defaults.capabilities = vim.tbl_deep_extend(
				"force",
				lspconfig_defaults.capabilities,
				require("cmp_nvim_lsp").default_capabilities()
			)

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

					if vim.api.nvim_buf_get_option(event.buf or 0, "filetype") == "cs" then
						vim.keymap.set(
							"n",
							"gr",
							"<cmd>lua require('omnisharp_extended').telescope_lsp_references()<cr>",
							opts
						)
						vim.keymap.set(
							"n",
							"gd",
							"<cmd>lua require('omnisharp_extended').telescope_lsp_definition({ jump_type = 'vsplit' })<cr>",
							opts
						)
						vim.keymap.set(
							"n",
							"<leader>D",
							"<cmd>lua require('omnisharp_extended').telescope_lsp_type_definition()<cr>",
							opts
						)
						vim.keymap.set(
							"n",
							"gi",
							"<cmd>lua require('omnisharp_extended').telescope_lsp_implementation()<cr>",
							opts
						)
					end
				end,
			})

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
			--lspconfig.quick_lint_js.setup({})
			lspconfig.omnisharp.setup({
				cmd = omnisharpCmd,

				settings = {
					FormattingOptions = {
						-- Enables support for reading code style, naming convention and analyzer
						-- settings from .editorconfig.
						EnableEditorConfigSupport = true,
						-- Specifies whether 'using' directives should be grouped and sorted during
						-- document formatting.
						OrganizeImports = nil,
					},
					MsBuild = {
						-- If true, MSBuild project system will only load projects for files that
						-- were opened in the editor. This setting is useful for big C# codebases
						-- and allows for faster initialization of code navigation features only
						-- for projects that are relevant to code that is being edited. With this
						-- setting enabled OmniSharp may load fewer projects and may thus display
						-- incomplete reference lists for symbols.
						LoadProjectsOnDemand = nil,
					},
					RoslynExtensionsOptions = {
						-- Enables support for roslyn analyzers, code fixes and rulesets.
						EnableAnalyzersSupport = nil,
						-- Enables support for showing unimported types and unimported extension
						-- methods in completion lists. When committed, the appropriate using
						-- directive will be added at the top of the current file. This option can
						-- have a negative impact on initial completion responsiveness,
						-- particularly for the first few completion sessions after opening a
						-- solution.
						EnableImportCompletion = nil,
						-- Only run analyzers against open files when 'enableRoslynAnalyzers' is
						-- true
						AnalyzeOpenDocumentsOnly = nil,
					},
					Sdk = {
						-- Specifies whether to include preview versions of the .NET SDK when
						-- determining which version to use for project loading.
						IncludePrereleases = true,
					},
				},
			})
		end,
	},
}
