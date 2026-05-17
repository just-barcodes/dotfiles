return {
	"lewis6991/gitsigns.nvim",
	opts = {
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local map = function(keys, func, desc)
				vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "Git: " .. desc })
			end
			map("<leader>hs", gs.stage_hunk, "[H]unk [S]tage / unstage")
			map("<leader>hr", gs.reset_hunk, "[H]unk [R]eset")
			map("<leader>hp", gs.preview_hunk, "[H]unk [P]review")
			map("<leader>hb", gs.blame_line, "[H]unk [B]lame")
			map("]h", gs.next_hunk, "Next hunk")
			map("[h", gs.prev_hunk, "Prev hunk")
		end,
	},
}
