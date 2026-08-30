return {
	"NeogitOrg/neogit",
	dependencies = { "sindrets/diffview.nvim", "folke/snacks.nvim" },
	cmd = "Neogit",
	opts = {
		integrations = { diffview = true, snacks = true },
		graph_style = "unicode",
		process_spinner = true,
		-- Only surface the command console when something actually failed.
		auto_show_console_on = "error",
		-- Status defaults to its own tab; "auto" keeps the other views beside
		-- it instead of stacking more tabs on top.
		commit_editor = { kind = "auto", staged_diff_split_kind = "vsplit" },
		commit_view = { kind = "auto" },
		log_view = { kind = "auto" },
		reflog_view = { kind = "auto" },
		stash = { kind = "auto" },
		refs_view = { kind = "auto" },
		popup = { kind = "split", show_title = true },
		sections = { recent = { folded = false } },
	},
	keys = {
		{ "<leader>gg", "<cmd>Neogit<CR>", desc = "[G]it Neo[G]it" },
	},
}
