return {
	"brianhuster/live-preview.nvim",
	cmd = "LivePreview",
	main = "livepreview",
	opts = { browser = "browser-here" }, -- ~/.local/bin/browser-here
	keys = {
		{ "<leader>tp", "<cmd>LivePreview start<cr>", desc = "[T]oggle live [P]review (start)" },
		{ "<leader>tP", "<cmd>LivePreview close<cr>", desc = "[T]oggle live [P]review (close)" },
	},
}
