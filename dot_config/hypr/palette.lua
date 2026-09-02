-- Colours for the current theme, read from ~/.config/theme/palettes/<name>.env.
-- The name comes from ~/.local/state/theme, both written by `theme-switch`.
-- A switch takes effect via `hyprctl reload`, which re-executes this config.

local home = os.getenv("HOME")

local function slurp(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

local state = slurp(home .. "/.local/state/theme")
local name = state and state:match("^%s*(%S+)") or "selenized-dark"

-- `key=value` per line, `#` comments. Same file that theme-switch sources and
-- quickshell/Theme.qml parses; see the note in selenized-dark.env.
local palette = {}
local env = slurp(home .. "/.config/theme/palettes/" .. name .. ".env")
for line in (env or ""):gmatch("[^\n]+") do
	if not line:match("^%s*#") then
		local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if k then
			palette[k] = v:match('^"(.*)"$') or v
		end
	end
end

-- Selenized Dark, matching the literals this module replaced, so a missing or
-- unreadable palette leaves hyprland looking exactly as it did before.
local fallback = {
	bg_0 = "#103c48",
	bg_2 = "#2d5b69",
	fg_0 = "#adbcbc",
	cyan = "#41c7b9",
	yellow = "#dbb32d",
	red = "#fa5750",
}

local function hex(key)
	local value = palette[key] or fallback[key] or "#000000"
	return (value:gsub("^#", ""))
end

local M = { name = name }

-- Hyprland wants rgba(RRGGBBAA) / rgb(RRGGBB), not #RRGGBB.
function M.rgba(key, alpha)
	return "rgba(" .. hex(key) .. alpha .. ")"
end

function M.rgb(key)
	return "rgb(" .. hex(key) .. ")"
end

return M
