-- Keybindings
-- https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"
local terminal = "ghostty"
local fileManager = "dolphin"
-- faster way to start walker via its socket; cannot run terminal commands
local menu = "nc -U /run/user/1000/walker/walker.sock"

-- Switch to a workspace, focus the app window if it exists, else launch it.
local function focus_or_launch(workspace, window_selector, launch_cmd)
	return function()
		hl.dispatch(hl.dsp.focus({ workspace = workspace, on_current_monitor = true }))
		if hl.get_window(window_selector) then
			hl.dispatch(hl.dsp.focus({ window = window_selector }))
		else
			hl.exec_cmd(launch_cmd)
		end
	end
end

----------------------------------------------------------------
-- Misc
----------------------------------------------------------------
hl.bind("CTRL + ALT + Q", hl.dsp.exec_cmd(terminal))
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + V", hl.dsp.window.pin())
hl.bind("ALT + space", hl.dsp.exec_cmd(menu))
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + F9", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- toggle notifications
hl.bind("SUPER + n", hl.dsp.exec_cmd("swaync-client -t -sw"))

----------------------------------------------------------------
-- TUI launcher
----------------------------------------------------------------
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd("~/.local/bin/tui-launcher"))

-- TUIs in the center
hl.window_rule({
	name = "windowrule-tui-centered",
	match = { class = "^(com\\.tui\\.centered)$" },
	float = true,
	size = { 1100, 700 },
	center = true,
})

-- TUIs covering the whole screen
hl.window_rule({
	name = "windowrule-tui-fullscreen",
	match = { class = "^(com\\.tui\\.fullscreen)$" },
	fullscreen = true,
})

----------------------------------------------------------------
-- DPMS bounce (run before unplugging external monitors)
----------------------------------------------------------------
hl.bind("SUPER + SHIFT + F9", hl.dsp.exec_cmd('hyprctl --batch "dispatch dpms off; sleep 2; dispatch dpms on"'))

hl.bind("CTRL + ALT + SHIFT + P", hl.dsp.exec_cmd("~/.local/bin/sesh-picker"))
hl.bind("CTRL + ALT + SHIFT + O", hl.dsp.exec_cmd("~/.local/bin/sesh-picker"))

----------------------------------------------------------------
-- Window splits
----------------------------------------------------------------
hl.bind("SUPER + equal", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + SHIFT + equal", hl.dsp.layout("swapsplit"))

----------------------------------------------------------------
-- Window groups (tabbed stack with groupbar)
-- SUPER + G toggles the focused window's tile into/out of a group.
-- Hyprland 0.55.1 does not expose `moveintogroup` to Lua, so existing
-- tiles cannot be merged programmatically — drag a tab onto the groupbar
-- to add another window, or rely on auto_group when spawning new ones.
-- Alt+Tab is a no-op outside a group, so it only acts when grouped.
----------------------------------------------------------------
hl.bind("SUPER + G", hl.dsp.group.toggle())
hl.bind("ALT + Tab", hl.dsp.group.next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.group.prev())

----------------------------------------------------------------
-- Minimize (replaces niflveil — its internal `hyprctl dispatch
-- movetoworkspace special:minimum,address:0x...` calls broke after
-- Hypr 0.55's Lua-eval dispatch). Active window → special:minimum;
-- restore brings the top of the stack back to the current workspace.
----------------------------------------------------------------
local MINIMIZED_WS = "special:minimum"
local minimized_stack = {}

local function pop_alive_minimized()
	while #minimized_stack > 0 do
		local addr = table.remove(minimized_stack)
		local sel = "address:" .. addr
		if hl.get_window(sel) then
			return sel
		end
	end
end

local function minimize_active()
	local w = hl.get_active_window()
	if not w or not w.workspace or w.workspace.special then
		return
	end
	table.insert(minimized_stack, w.address)
	hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED_WS, follow = false }))
end

local function restore_last()
	local ws = hl.get_active_workspace()
	if not ws or ws.special then
		return
	end
	local sel = pop_alive_minimized()
	if not sel then
		return
	end
	-- Focus reveals special:minimum; follow=true rides the window back to ws.
	hl.dispatch(hl.dsp.focus({ window = sel }))
	hl.dispatch(hl.dsp.window.move({ workspace = ws.id, follow = true }))
end

local function restore_all()
	local ws = hl.get_active_workspace()
	if not ws or ws.special then
		return
	end
	while true do
		local sel = pop_alive_minimized()
		if not sel then
			break
		end
		hl.dispatch(hl.dsp.focus({ window = sel }))
		hl.dispatch(hl.dsp.window.move({ workspace = ws.id, follow = false }))
	end
	-- Land back on the originating workspace (we may still be on special:minimum).
	hl.dispatch(hl.dsp.focus({ workspace = ws.id, on_current_monitor = true }))
end

hl.bind(mainMod .. " + M", minimize_active)
hl.bind("SUPER + U", restore_last)
hl.bind(mainMod .. " + SHIFT + U", restore_all)

----------------------------------------------------------------
-- Resize windows
----------------------------------------------------------------
hl.bind("SUPER + CTRL + h", hl.dsp.window.resize({ x = -260, y = 0, relative = true }))
hl.bind("SUPER + CTRL + l", hl.dsp.window.resize({ x = 260, y = 0, relative = true }))
hl.bind("SUPER + CTRL + k", hl.dsp.window.resize({ x = 0, y = -140, relative = true }))
hl.bind("SUPER + CTRL + j", hl.dsp.window.resize({ x = 0, y = 140, relative = true }))

----------------------------------------------------------------
-- Spotify (M / 96)
----------------------------------------------------------------
hl.bind("SUPER + ALT + M", focus_or_launch(96, "class:^Spotify$", "spotify-launcher"))
hl.window_rule({
	name = "windowrule-spotify",
	match = { class = "^(Spotify)$" },
	workspace = "96",
})
hl.bind("SUPER + ALT + SHIFT + m", hl.dsp.window.move({ workspace = 96, follow = false }))

----------------------------------------------------------------
-- Obsidian (O / 70)
----------------------------------------------------------------
hl.bind("SUPER + ALT + O", focus_or_launch(70, "class:^(obsidian|Obsidian)$", "obsidian"))
hl.window_rule({
	name = "windowrule-obsidian",
	match = { class = "^(obsidian)$" },
	workspace = "70",
})
hl.bind("SUPER + ALT + SHIFT + o", hl.dsp.window.move({ workspace = 70, follow = false }))

----------------------------------------------------------------
-- ChatGPT (I / 80)
----------------------------------------------------------------
hl.bind("SUPER + ALT + I", focus_or_launch(80, "class:^CHATGPT$", "gtk-launch chatgpt"))
hl.window_rule({
	name = "windowrule-chatgpt",
	match = { class = "^(CHATGPT)$" },
	workspace = "80",
})
hl.bind("SUPER + ALT + SHIFT + i", hl.dsp.window.move({ workspace = 80, follow = false }))

----------------------------------------------------------------
-- YouTube (Y / 95)
----------------------------------------------------------------
hl.bind("SUPER + ALT + Y", focus_or_launch(95, "class:^YOUTUBE$", "gtk-launch youtube"))
hl.window_rule({
	name = "windowrule-youtube",
	match = { class = "^(YOUTUBE)$" },
	workspace = "95",
})
hl.bind("SUPER + ALT + SHIFT + y", hl.dsp.window.move({ workspace = 95, follow = false }))

----------------------------------------------------------------
-- Teams (T / 91)
----------------------------------------------------------------
hl.bind(
	"SUPER + ALT + T",
	focus_or_launch(91, "class:^chrome-teams\\.microsoft\\.com.*$", "gtk-launch teams")
)
hl.window_rule({
	name = "windowrule-teams",
	match = { class = "^chrome-teams\\.microsoft\\.com.*$" },
	workspace = "91",
})
hl.bind("SUPER + ALT + SHIFT + t", hl.dsp.window.move({ workspace = 91, follow = false }))

----------------------------------------------------------------
-- Email / Betterbird (U / 90)
----------------------------------------------------------------
hl.bind("SUPER + ALT + U", focus_or_launch(90, "class:^eu\\.betterbird\\.Betterbird$", "betterbird"))
hl.window_rule({
	name = "windowrule-betterbird",
	match = { class = "^(eu.betterbird.Betterbird)$" },
	workspace = "90",
})
hl.bind("SUPER + ALT + SHIFT + u", hl.dsp.window.move({ workspace = 90, follow = false }))

----------------------------------------------------------------
-- Lazydocker (D / 98)
----------------------------------------------------------------
hl.bind("SUPER + ALT + D", hl.dsp.focus({ workspace = 98, on_current_monitor = true }))
hl.bind("SUPER + ALT + SHIFT + D", hl.dsp.window.move({ workspace = 98, follow = false }))

----------------------------------------------------------------
-- System monitor (0 / 99)
----------------------------------------------------------------
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 99, on_current_monitor = true }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 99, follow = false }))

----------------------------------------------------------------
-- Tmux (, / 50)
----------------------------------------------------------------
hl.bind("SUPER + ALT + comma", hl.dsp.focus({ workspace = 50, on_current_monitor = true }))
hl.bind("SUPER + ALT + SHIFT + comma", hl.dsp.window.move({ workspace = 50, follow = false }))

----------------------------------------------------------------
-- Home rows (h/j/k/l / 1, 2, 3, 4)
----------------------------------------------------------------
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1, on_current_monitor = true }))
hl.bind("SUPER + ALT + h", hl.dsp.focus({ workspace = 1, on_current_monitor = true }))
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1, follow = false }))
hl.bind("SUPER + ALT + SHIFT + h", hl.dsp.window.move({ workspace = 1, follow = false }))

hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2, on_current_monitor = true }))
hl.bind("SUPER + ALT + j", hl.dsp.focus({ workspace = 2, on_current_monitor = true }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2, follow = false }))
hl.bind("SUPER + ALT + SHIFT + j", hl.dsp.window.move({ workspace = 2, follow = false }))

hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3, on_current_monitor = true }))
hl.bind("SUPER + ALT + k", hl.dsp.focus({ workspace = 3, on_current_monitor = true }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3, follow = false }))
hl.bind("SUPER + ALT + SHIFT + k", hl.dsp.window.move({ workspace = 3, follow = false }))

hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4, on_current_monitor = true }))
hl.bind("SUPER + ALT + l", hl.dsp.focus({ workspace = 4, on_current_monitor = true }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4, follow = false }))
hl.bind("SUPER + ALT + SHIFT + l", hl.dsp.window.move({ workspace = 4, follow = false }))

----------------------------------------------------------------
-- IDE (. / 60)
----------------------------------------------------------------
hl.bind("SUPER + ALT + period", hl.dsp.focus({ workspace = 60, on_current_monitor = true }))
hl.bind("SUPER + ALT + SHIFT + period", hl.dsp.window.move({ workspace = 60, follow = false }))

----------------------------------------------------------------
-- Special: magic (S)
----------------------------------------------------------------
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

----------------------------------------------------------------
-- Move focus
----------------------------------------------------------------
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

----------------------------------------------------------------
-- Mouse: move/resize with mainMod + LMB/RMB and dragging
----------------------------------------------------------------
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

----------------------------------------------------------------
-- Multimedia
----------------------------------------------------------------
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),
	{ locked = true, repeating = true }
)

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"))

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
