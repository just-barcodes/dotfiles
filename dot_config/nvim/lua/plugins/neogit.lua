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
		status = { recent_commit_count = 30 },
		-- Neogit hides "Recent Commits" whenever an unmerged section is on
		-- screen, so having unpushed work costs you the whole history. Hide the
		-- unmerged sections instead: "Recent Commits" then lists everything and
		-- the unpushed commits get tinted below.
		sections = {
			recent = { folded = false },
			unmerged_upstream = { hidden = true },
			unmerged_pushRemote = { hidden = true },
		},
	},
	config = function(_, opts)
		require("neogit").setup(opts)

		-- NeogitGraphOrange resolves to the same violet as the author margin
		-- and the neogit palette has no colour that is not already used by the
		-- hash, branch, remote or tag. Statement is the theme's yellow accent
		-- and is unused in the status buffer.
		vim.api.nvim_set_hl(0, "NeogitUnmergedCommit", { link = "Statement" })

		-- Tint the commits that are not yet on the upstream/push remote. Neogit
		-- renders every commit the same way, so the highlight has to be applied
		-- after each render, keyed off the oids in the repo state.
		local unmerged_ns = vim.api.nvim_create_namespace("neogit-unmerged-commits")

		local function highlight_unmerged()
			local instance = require("neogit.buffers.status").instance()
			if not (instance and instance.buffer and instance.buffer.ui) then
				return
			end

			local handle = instance.buffer.handle
			vim.api.nvim_buf_clear_namespace(handle, unmerged_ns, 0, -1)

			local ui = instance.buffer.ui
			local repo = require("neogit.lib.git").repo.state
			for _, source in ipairs({ repo.upstream.unmerged.items, repo.pushRemote.unmerged.items }) do
				for _, commit in ipairs(source) do
					local item = ui:find_component_by_oid(commit.oid)
					if item and item.first then
						vim.api.nvim_buf_set_extmark(handle, unmerged_ns, item.first - 1, 0, {
							line_hl_group = "NeogitUnmergedCommit",
						})
					end
				end
			end
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = "NeogitStatusRefreshed",
			group = vim.api.nvim_create_augroup("neogit-unmerged-commits", { clear = true }),
			callback = vim.schedule_wrap(highlight_unmerged),
		})

		-- Neogit has no live preview pane: its "PeekFile" mapping is listed in
		-- the defaults but never wired up in the status buffer, and diffs are
		-- meant to be expanded inline instead. This shows the diff of the file
		-- under the cursor in a split on the right, lazygit style.
		local preview = { win = nil, buf = nil, last = nil }

		local function close()
			if preview.win and vim.api.nvim_win_is_valid(preview.win) then
				vim.api.nvim_win_close(preview.win, true)
			end
			preview.win, preview.last = nil, nil
		end

		local function show(lines, title)
			if not (preview.buf and vim.api.nvim_buf_is_valid(preview.buf)) then
				preview.buf = vim.api.nvim_create_buf(false, true)
				vim.bo[preview.buf].bufhidden = "hide"
				vim.bo[preview.buf].filetype = "diff"
			end

			if not (preview.win and vim.api.nvim_win_is_valid(preview.win)) then
				local status_win = vim.api.nvim_get_current_win()
				vim.cmd("noautocmd vertical rightbelow split")
				preview.win = vim.api.nvim_get_current_win()
				vim.api.nvim_win_set_buf(preview.win, preview.buf)
				vim.wo[preview.win].number = false
				vim.wo[preview.win].relativenumber = false
				vim.wo[preview.win].winfixwidth = true
				vim.api.nvim_set_current_win(status_win)
			end

			vim.bo[preview.buf].modifiable = true
			vim.api.nvim_buf_set_lines(preview.buf, 0, -1, false, lines)
			vim.bo[preview.buf].modifiable = false
			vim.wo[preview.win].winbar = title or ""
		end

		local function update()
			local instance = require("neogit.buffers.status").instance()
			if not (instance and instance.buffer and instance.buffer.ui) then
				return
			end

			local item = instance.buffer.ui:get_item_under_cursor()
			-- Section headers and commit entries have no diff; keep whatever
			-- was last shown rather than flickering the split empty.
			if not (item and item.diff and #item.diff.lines > 0) then
				return
			end
			if item.name == preview.last and preview.win and vim.api.nvim_win_is_valid(preview.win) then
				return
			end

			preview.last = item.name
			show(item.diff.lines, item.name)
		end

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "NeogitStatus",
			group = vim.api.nvim_create_augroup("neogit-diff-preview", { clear = true }),
			callback = function(ev)
				vim.api.nvim_create_autocmd("CursorMoved", {
					buffer = ev.buf,
					callback = update,
				})
				vim.api.nvim_create_autocmd({ "BufWipeout", "BufHidden" }, {
					buffer = ev.buf,
					callback = close,
				})
			end,
		})
	end,
	keys = {
		{ "<leader>gg", "<cmd>Neogit<CR>", desc = "[G]it Neo[G]it" },
	},
}
