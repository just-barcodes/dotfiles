-- Fuzzy Finder (files, lsp, etc) + LazyGit + Explorer + Input
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		picker = { enabled = true },
		lazygit = { enabled = true },
		explorer = { enabled = true },
		input = { enabled = true },
	},
	keys = {
		{
			"<leader>e",
			function()
				Snacks.explorer()
			end,
			desc = "Toggle file tree",
		},
		{
			"<leader>gl",
			function()
				Snacks.lazygit()
			end,
			desc = "[G]it [L]azygit",
		},
		{
			"<leader>gk",
			function()
				Snacks.terminal("hunk diff", { win = { style = "float" } })
			end,
			desc = "[G]it hun[K] diff",
		},
		{
			"<leader>sh",
			function()
				Snacks.picker.help()
			end,
			desc = "[S]earch [H]elp",
		},
		{
			"<leader>sk",
			function()
				Snacks.picker.keymaps()
			end,
			desc = "[S]earch [K]eymaps",
		},
		{
			"<leader>sf",
			function()
				Snacks.picker.files()
			end,
			desc = "[S]earch [F]iles",
		},
		{
			"<C-p>",
			function()
				Snacks.picker.files({
					hidden = true,
					exclude = {
						".git",
						".cache",
						".venv",
						".mypy_cache",
						".pytest_cache",
						".ruff_cache",
						"__pycache__",
						"node_modules",
						".DS_Store",
					},
				})
			end,
			desc = "[S]earch [F]iles (incl. hidden)",
		},
		{
			"<leader>ss",
			function()
				Snacks.picker()
			end,
			desc = "[S]earch [S]elect Picker",
		},
		{
			"<leader>sw",
			function()
				Snacks.picker.grep_word()
			end,
			mode = { "n", "x" },
			desc = "[S]earch current [W]ord",
		},
		{
			"<leader>sg",
			function()
				Snacks.picker.grep()
			end,
			desc = "[S]earch by [G]rep",
		},
		{
			"<leader>sd",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "[S]earch [D]iagnostics",
		},
		{
			"<leader>sr",
			function()
				Snacks.picker.resume()
			end,
			desc = "[S]earch [R]esume",
		},
		{
			"<leader>s.",
			function()
				Snacks.picker.recent()
			end,
			desc = '[S]earch Recent Files ("." for repeat)',
		},
		{
			"<leader><leader>",
			function()
				Snacks.picker.buffers()
			end,
			desc = "[ ] Find existing buffers",
		},
		{
			"<leader>/",
			function()
				Snacks.picker.lines()
			end,
			desc = "[/] Fuzzily search in current buffer",
		},
		{
			"<leader>s/",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "[S]earch [/] in Open Files",
		},
		{
			"<leader>sn",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "[S]earch [N]eovim files",
		},
	},
}
