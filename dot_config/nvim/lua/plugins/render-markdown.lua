return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
	ft = { "markdown", "opencode_output" },
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		anti_conceal = { enabled = false },
		file_types = { "markdown", "opencode_output" },
		heading = {
			sign = false,
			position = "inline",
			icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			width = "block",
			left_pad = 1,
			right_pad = 2,
			min_width = 60,
			border = true,
		},
		code = {
			sign = false,
			width = "block",
			right_pad = 2,
			min_width = 60,
			border = "thick",
			language_pad = 2,
			language_icon = true,
		},
		bullet = {
			icons = { "●", "○", "◆", "◇" },
		},
		checkbox = {
			unchecked = { icon = "󰄱 " },
			checked = { icon = "󰱒 " },
			custom = {
				todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
				in_progress = { raw = "[~]", rendered = "󰓏 ", highlight = "RenderMarkdownWarn" },
			},
		},
		pipe_table = {
			preset = "round",
		},
		quote = { icon = "▌" },
		link = {
			wiki = { icon = "󰈙 ", color = "RenderMarkdownLink" },
			custom = {
				web = { pattern = "^http", icon = "󰖟 " },
				github = { pattern = "github%.com", icon = " " },
			},
		},
	},
	keys = {
		{ "<leader>tm", "<cmd>RenderMarkdown toggle<cr>", desc = "[T]oggle [M]arkdown render" },
		{ "<leader>te", "<cmd>RenderMarkdown expand<cr>", desc = "[T]oggle markdown [E]xpand" },
	},
}
