-- Filetype detection for chezmoi source files (dot_foo → ~/.foo).
-- Treesitter, LSP, and formatters key off filetype, so this is all that's
-- needed to get full highlighting in the chezmoi repo.
vim.filetype.add({
	pattern = {
		[".*/chezmoi/.*/?dot_zshrc"] = "zsh",
		[".*/chezmoi/.*/?dot_zprofile"] = "zsh",
		[".*/chezmoi/.*/?dot_bashrc"] = "bash",
		[".*/chezmoi/.*/?dot_bash_profile"] = "bash",
		[".*/chezmoi/.*/?dot_tmux%.conf"] = "tmux",
		[".*/chezmoi/.*/?dot_gitconfig"] = "gitconfig",
		[".*/chezmoi/.*/?dot_gitignore_global"] = "gitignore",
		[".*/chezmoi/.*/?dot_ideavimrc"] = "vim",
		[".*/chezmoi/.*/?dot_vimrc"] = "vim",
		[".*/chezmoi/.*/?private_dot_npmrc"] = "conf",
	},
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Ensure C-hjkl navigate out of :terminal buffers (snacks.nvim / Claude Code).
-- Set buffer-local tnoremap so plugin-set buffer-local maps can't shadow them.
vim.api.nvim_create_autocmd("TermOpen", {
	desc = "Install tmux-navigator keymaps in terminal buffers",
	group = vim.api.nvim_create_augroup("term-nav-keys", { clear = true }),
	callback = function(ev)
		local opts = { buffer = ev.buf, silent = true }
		vim.keymap.set("t", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", opts)
		vim.keymap.set("t", "<C-j>", "<cmd>TmuxNavigateDown<CR>", opts)
		vim.keymap.set("t", "<C-k>", "<cmd>TmuxNavigateUp<CR>", opts)
		vim.keymap.set("t", "<C-l>", "<cmd>TmuxNavigateRight<CR>", opts)
	end,
})

-- If closing a window would leave only the Claude Code terminal visible,
-- open an empty buffer alongside it so Claude doesn't fill the whole screen.
local function is_claude_win(win)
	if not vim.api.nvim_win_is_valid(win) then
		return false
	end
	local buf = vim.api.nvim_win_get_buf(win)
	if vim.bo[buf].buftype ~= "terminal" then
		return false
	end
	local name = vim.api.nvim_buf_get_name(buf)
	return name:lower():find("claude") ~= nil
end

vim.api.nvim_create_autocmd("WinClosed", {
	desc = "Keep an empty buffer open beside Claude Code",
	group = vim.api.nvim_create_augroup("claude-keep-buffer", { clear = true }),
	callback = function(ev)
		local closed = tonumber(ev.match)
		vim.schedule(function()
			local wins = vim.tbl_filter(function(w)
				return w ~= closed and vim.api.nvim_win_get_config(w).relative == ""
			end, vim.api.nvim_tabpage_list_wins(0))
			if #wins == 1 and is_claude_win(wins[1]) then
				vim.api.nvim_set_current_win(wins[1])
				vim.cmd("leftabove vnew")
			end
		end)
	end,
})

-- Wrap long lines in Claude Code diff windows. Row-for-row alignment between
-- the two panes drifts once lines wrap — <leader>aw toggles wrap on both
-- panes when the drift matters.
local function is_claude_diff_buf(buf)
	if
		vim.b[buf].claudecode_diff_tab_name
		or vim.b[buf].claudecode_diff_new_win
		or vim.b[buf].claudecode_diff_target_win
	then
		return true
	end
	local name = vim.api.nvim_buf_get_name(buf)
	return name:find("%(proposed%)") ~= nil
		or name:find("%(NEW FILE %- proposed%)") ~= nil
		or name:find("%(New%)") ~= nil
end

-- Right (proposed) pane is a scratch buffer named "<tab_name> (proposed)" —
-- fall back to the paired target window's buffer name to get the real path.
local function claude_diff_path(buf)
	local target = vim.b[buf].claudecode_diff_target_win
	if target and vim.api.nvim_win_is_valid(target) then
		return vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(target))
	end
	return vim.api.nvim_buf_get_name(buf)
end

vim.api.nvim_create_autocmd("BufWinEnter", {
	desc = "Enable wrap + toggle keymap in Claude Code diff buffers",
	group = vim.api.nvim_create_augroup("claude-diff-wrap", { clear = true }),
	callback = function(ev)
		if not is_claude_diff_buf(ev.buf) then
			return
		end
		vim.wo[0].wrap = true
		vim.wo[0].linebreak = true
		vim.wo[0].winbar = vim.fn.fnamemodify(claude_diff_path(ev.buf), ":~:.")
		vim.keymap.set("n", "<leader>aw", function()
			for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				if vim.wo[w].diff then
					vim.wo[w].wrap = not vim.wo[w].wrap
				end
			end
		end, { buffer = ev.buf, desc = "Toggle [W]rap in Claude diff" })
	end,
})

