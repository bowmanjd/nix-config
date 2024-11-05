return {
	{
		"rcarriga/nvim-notify",
    keys = {
      {
        "<leader>m",
        "<cmd>lua notify.dismiss()<cr>",
        desc = "Dismiss notifications",
      },
    },
		config = function()
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
		end,
	},
}
