home = os.getenv("HOME") or os.getenv("USERPROFILE")

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.hidden = true
vim.opt.mouse = "a"

vim.opt.fileformat = "unix"
vim.opt.fileformats = { "unix", "dos" }

vim.opt.backup = false
vim.opt.writebackup = true

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
