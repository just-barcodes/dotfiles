-- [[ Global options ]]
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- [[ Setting options ]]
require("options")

-- [[ Basic Keymaps ]]
require("keymaps")

-- [[ Basic Autocommands ]]
require("autocommands")

-- [[ Plugins (skipped when running inside VSCode) ]]
if vim.fn.exists("g:vscode") == 0 then
	require("lazy-bootstrap")
	require("lazy-plugins")
end

-- vim: ts=2 sts=2 sw=2 et
