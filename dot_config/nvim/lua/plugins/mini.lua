-- Collection of various small independent plugins/modules
return {
	"echasnovski/mini.nvim",
	config = function()
		-- Better Around/Inside textobjects
		--   va)  - [V]isually select [A]round [)]paren
		--   yinq - [Y]ank [I]nside [N]ext [Q]uote
		--   ci'  - [C]hange [I]nside [']quote
		require("mini.ai").setup({ n_lines = 500 })

		-- Add/delete/replace surroundings (brackets, quotes, etc.)
		--   saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
		--   sd'   - [S]urround [D]elete [']quotes
		--   sr)'  - [S]urround [R]eplace [)] [']
		require("mini.surround").setup()

		-- Icons (mocks nvim-web-devicons API for plugins that expect it).
		require("mini.icons").setup()
		MiniIcons.mock_nvim_web_devicons()

		-- Simple statusline.
		local statusline = require("mini.statusline")
		statusline.setup({ use_icons = vim.g.have_nerd_font })

		-- Cursor location as LINE:COLUMN.
		---@diagnostic disable-next-line: duplicate-set-field
		statusline.section_location = function()
			return "%2l:%-2v"
		end
	end,
}
