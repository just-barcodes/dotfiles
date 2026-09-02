-- One colorscheme per palette family in ~/.config/theme/palettes. The active
-- one is read at startup from the palette's `nvim_colorscheme` key (the palette
-- name comes from ~/.local/state/theme); `theme-switch` moves running instances
-- over their RPC socket. The parser matches hypr/palette.lua.
local function active()
	local home = os.getenv("HOME")
	local scheme, polarity = "selenized", "dark"

	local state = io.open(home .. "/.local/state/theme")
	if not state then
		return scheme, polarity
	end
	local name = (state:read("*l") or ""):match("^%s*(%S+)") or "selenized-dark"
	state:close()

	local env = io.open(home .. "/.config/theme/palettes/" .. name .. ".env")
	if not env then
		return scheme, polarity
	end
	for line in env:lines() do
		local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if k == "nvim_colorscheme" then
			scheme = v
		elseif k == "polarity" then
			polarity = v
		end
	end
	env:close()
	return scheme, polarity
end

return {
	{
		"calind/selenized.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local scheme, polarity = active()
			vim.o.background = polarity
			-- Selenized always loads first: neogit.lua reads _G.selenized.colors,
			-- which only exists once the selenized colorscheme has run.
			vim.cmd.colorscheme("selenized")
			if scheme ~= "selenized" then
				vim.cmd.colorscheme(scheme)
			end
		end,
	},
	-- lazy.nvim loads these on `:colorscheme <name>`, so an unused family
	-- costs nothing at startup.
	{ "ellisonleao/gruvbox.nvim", lazy = true },
	{ "catppuccin/nvim", name = "catppuccin", lazy = true },
	{ "rose-pine/neovim", name = "rose-pine", lazy = true },
}
