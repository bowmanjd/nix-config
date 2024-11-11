return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
    "rcarriga/nvim-notify",
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
	},
	cmd = {
		"DB",
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	keys = {
		{
			"<leader>S",
			"<Plug>(DBUI_ExecuteQuery)<cr>",
			mode = { "n", "v" },
			desc = "Execute SQL query",
		},
		{
			"<leader>d",
			"<cmd>DBUIFindBuffer<cr>",
			desc = "Select database",
		},
	},
	init = function()
		vim.g.db_ui_use_nerd_fonts = 1
		vim.g.db_ui_execute_on_save = 0
    vim.g.db_ui_use_nvim_notify = 1
	end,
}