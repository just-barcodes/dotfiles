-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous [D]iagnostic" })
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next [D]iagnostic" })
vim.keymap.set("n", "<C-,>", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next [D]iagnostic" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Split navigation (C-hjkl) is handled by vim-tmux-navigator in normal mode
-- (see lazy-plugins.lua) and reinforced per-terminal-buffer by an autocmd in
-- autocommands.lua so plugin-set buffer-local maps can't shadow them.

-- Suspend Neovim from terminal mode too, so <C-z> in the Claude Code split
-- backgrounds the whole editor instead of being sent to the terminal program.
vim.keymap.set("t", "<C-z>", "<cmd>suspend<CR>", { desc = "Suspend Neovim" })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

vim.keymap.set("n", "<Leader>p", '"+p', { desc = "Paste from shared clipboard" })
vim.keymap.set("n", "<Leader>P", '"+P', { desc = "Paste from shared clipboard" })
vim.keymap.set("v", "<Leader>y", '"+y', { desc = "Copy into shared clipboard" })

-- use ctrl / to comment
vim.keymap.set("n", "<C-_>", "gcc", { remap = true })
vim.keymap.set("v", "<C-_>", "gc", { remap = true })

-- save using ctrl s
vim.keymap.set("n", "<C-s>", ":w<CR>", { noremap = true, silent = true })

-- disable ZZ (write-and-quit) to avoid accidental quits
vim.keymap.set("n", "ZZ", "<Nop>", { noremap = true })
-- vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>i", { noremap = true, silent = true })
