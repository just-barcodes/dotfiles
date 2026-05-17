return {
	"sudo-tee/opencode.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		preferred_picker = "snacks",
		preferred_completion = "blink",
		keymap = {
			model_picker = {
				toggle_favorite = { "<M-f>", mode = { "i", "n" } },
			},
			input_window = {
				["<esc>"] = false,
			},
			output_window = {
				["<esc>"] = false,
			},
		},
	},
	keys = {
		{ "<leader>og", desc = "Toggle Opencode" },
		{ "<leader>oi", desc = "Open Opencode input" },
		{ "<leader>oo", desc = "Open Opencode output" },
		{ "<leader>os", desc = "Select Opencode session" },
		{ "<leader>op", desc = "Configure provider/model" },
	},
}
