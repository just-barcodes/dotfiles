return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		suggestion = { enabled = false }, -- handled by blink-cmp-copilot
		panel = { enabled = false },
		filetypes = { markdown = true, yaml = true, sh = true },
	},
}
