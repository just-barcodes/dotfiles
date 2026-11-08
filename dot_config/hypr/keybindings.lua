-- Keybindings
-- https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"
local terminal = "ghostty"
local fileManager = "dolphin"
-- faster way to start walker via its socket; cannot run terminal commands
local menu = 'nc -U "$XDG_RUNTIME_DIR/walker/walker.sock"'

-- Switch to a workspace, launching the app if it has no window yet.
-- Deliberately no `focus({window = selector})` afterwards: the workspace
-- switch already restores that workspace's last-focused window, and a
-- `class:` selector resolves to one fixed match, so re-focusing would snap
-- to the same window every time when several share the class.
local function focus_or_launch(workspace, window_selector, launch_cmd)
	return function()
		hl.dispatch(hl.dsp.focus({ workspace = workspace, on_current_monitor = true }))
		if not hl.get_window(window_selector) then
			hl.exec_cmd(launch_cmd)
		end
	end
end

-- Pin a single app to a workspace: SUPER+ALT+<key> focuses/launches it,
-- SUPER+ALT+SHIFT+<key> moves the focused window there, and <rule> pins it.
local function bind_app_workspace(key, workspace, selector, launch_cmd, rule)
	hl.bind("SUPER + ALT + " .. key, focus_or_launch(workspace, selector, launch_cmd))
	hl.window_rule(rule)
	hl.bind("SUPER + ALT + SHIFT + " .. key:lower(), hl.dsp.window.move({ workspace = workspace, follow = false }))
end

local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
	end
	return f ~= nil
end

-- Group on open instead of a `group = "set"` rule: that rule only merges the
-- second window if the first one's group is focused when it maps, which
-- depends on launch timing. Here a later window matching <is_member> joins
-- the earlier one on <workspace>.
local function group_on_open(workspace, is_member)
	hl.on("window.open", function(w)
		if not (w and is_member(w) and not w.group and w.workspace and w.workspace.id == workspace) then
			return
		end
		for _, other in ipairs(w.workspace:get_windows()) do
			if other.address ~= w.address and is_member(other) then
				local g = other.group
				if not g then
					hl.dispatch(hl.dsp.focus({ window = "address:" .. other.address }))
					hl.dispatch(hl.dsp.group.toggle())
					local active = hl.get_active_window()
					g = active and active.group
				end
				if g then
					g:add(w)
				end
				-- group:add() drops keyboard focus entirely (active window becomes nil)
				hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
				return
			end
		end
	end)
end

----------------------------------------------------------------
-- Misc
----------------------------------------------------------------
hl.bind("CTRL + ALT + Q", hl.dsp.exec_cmd(terminal))
-- Ctrl+Q: swallowed in Orca (its File > Exit is an Electron menu accelerator
-- that ~/.orca/keybindings.json cannot unbind), forwarded to any other window.
hl.bind("CTRL + Q", function()
	local w = hl.get_active_window()
	if not w or w.class == "orca" then
		return
	end
	hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "q" }))
end)
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + V", hl.dsp.window.pin())
hl.bind("ALT + space", hl.dsp.exec_cmd(menu))
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd("qs ipc call lock lock"))
hl.bind("SUPER + F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + F9", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- toggle notifications
hl.bind("SUPER + n", hl.dsp.exec_cmd("qs ipc call notifs toggle"))

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

-- Large floating TUIs (pacsea, pkgpick): 85% of the screen, centered
hl.window_rule({
	name = "windowrule-tui-large",
	match = { class = "^(com\\.tui\\.large)$" },
	float = true,
	size = { "monitor_w*0.85", "monitor_h*0.85" },
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

-- agent sessions picker: elephant menu over `sm-switch.sh list` (plain sm-switch.sh is the dmenu fallback)
hl.bind("CTRL + ALT + SHIFT + I", hl.dsp.exec_cmd("walker -m menus:agents --width 1280 --height 630 --nohints"))
-- sessions picker: elephant menu over sesh-picker's cache (plain `sesh-picker` is the dmenu fallback)
hl.bind("CTRL + ALT + SHIFT + O", hl.dsp.exec_cmd("walker -m menus:sessions --width 1280 --height 630 --nohints"))
hl.bind("CTRL + ALT + SHIFT + T", hl.dsp.exec_cmd("~/.local/bin/theme-switch"))

----------------------------------------------------------------
-- Window splits
----------------------------------------------------------------
hl.bind("SUPER + equal", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + SHIFT + equal", hl.dsp.layout("swapsplit"))

----------------------------------------------------------------
-- Window groups (tabbed stack with groupbar)
-- SUPER + G: if the focused window is ungrouped, group it and absorb
-- every other tiled window on the workspace (0.56 exposes group:add()
-- to Lua, so merging existing tiles works now); if it is grouped,
-- toggle dissolves the whole group back into tiles.
-- Alt+Tab is a no-op outside a group, so it only acts when grouped.
----------------------------------------------------------------
local function toggle_group_workspace()
	local w = hl.get_active_window()
	if not w then
		return
	end
	if w.group then
		hl.dispatch(hl.dsp.group.toggle())
		return
	end
	hl.dispatch(hl.dsp.group.toggle())
	w = hl.get_active_window()
	local g = w and w.group
	local ws = w and w.workspace
	if not (g and ws) then
		return
	end
	for _, win in ipairs(ws:get_windows()) do
		if not win.floating and not win.group then
			g:add(win)
		end
	end
	-- group:add() drops keyboard focus entirely (active window becomes nil)
	hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
end

hl.bind("SUPER + G", toggle_group_workspace)
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
bind_app_workspace("M", 96, "class:^Spotify$", "spotify-launcher", {
	name = "windowrule-spotify",
	match = { class = "^(Spotify)$" },
	workspace = "96",
})

----------------------------------------------------------------
-- Obsidian (O / 70)
----------------------------------------------------------------
bind_app_workspace("O", 70, "class:.*[Oo]bsidian$", "obsidian", {
	name = "windowrule-obsidian",
	match = { class = ".*[Oo]bsidian$" },
	workspace = "70",
})

----------------------------------------------------------------
-- ChatGPT (I / 80)
----------------------------------------------------------------
bind_app_workspace("I", 80, "class:^CHATGPT$", "gtk-launch chatgpt", {
	name = "windowrule-chatgpt",
	match = { class = "^(CHATGPT)$" },
	workspace = "80",
})

----------------------------------------------------------------
-- YouTube (Y / 95)
----------------------------------------------------------------
bind_app_workspace("Y", 95, "class:^YOUTUBE$", "gtk-launch youtube", {
	name = "windowrule-youtube",
	match = { class = "^(YOUTUBE)$" },
	workspace = "95",
})

----------------------------------------------------------------
-- Multi-app slots: Mail (U / 90), Chat (T / 91), Tasks (P / 40)
-- ~/.config/hypr/local_apps.lua (machine-local, untracked) picks which
-- catalog apps each slot launches and whether they form a tabbed group;
-- see local_apps.lua.example. A slot missing from that file launches every
-- installed app in its default list, grouped. Window rules cover all of a
-- slot's apps either way, so a manually started one still lands there.
----------------------------------------------------------------
local apps_dir = os.getenv("HOME") .. "/.local/share/applications/"

-- rule: Hyprland regex on the window class; lua: the same as Lua patterns
-- (for grouping); needs: files that must exist for the fallback to launch it.
local app_catalog = {
	["proton-mail"] = {
		rule = "^(Proton Mail|proton-mail)$",
		lua = { "^Proton Mail$", "^proton%-mail$" },
		launch = "proton-mail",
		needs = { "/usr/bin/proton-mail" },
	},
	outlook = {
		rule = "^chrome-outlook\\.office\\.com.*$",
		lua = { "^chrome%-outlook%.office%.com" },
		launch = "gtk-launch outlook",
		needs = { apps_dir .. "outlook.desktop", "/usr/bin/chromium" },
	},
	teams = {
		rule = "^chrome-teams\\.microsoft\\.com.*$",
		lua = { "^chrome%-teams%.microsoft%.com" },
		launch = "gtk-launch teams",
		needs = { apps_dir .. "teams.desktop", "/usr/bin/chromium" },
	},
	slack = {
		rule = "^Slack$",
		lua = { "^Slack$" },
		launch = "slack",
		needs = { "/usr/bin/slack" },
	},
	tasks = {
		rule = "^TASKS$",
		lua = { "^TASKS$" },
		launch = "gtk-launch tasks",
		needs = { apps_dir .. "tasks.desktop" },
	},
	tududi = {
		rule = "^TUDUDI$",
		lua = { "^TUDUDI$" },
		launch = "gtk-launch tududi",
		needs = { apps_dir .. "tududi.desktop" },
	},
}

-- apps: pinned to the workspace and grouped; default: launched (if installed)
-- when local_apps.lua does not configure the slot.
local app_slots = {
	{ name = "mail", key = "U", workspace = 90, apps = { "proton-mail", "outlook" }, default = { "proton-mail", "outlook" } },
	{ name = "chat", key = "T", workspace = 91, apps = { "teams", "slack" }, default = { "slack" } },
	{ name = "tasks", key = "P", workspace = 40, apps = { "tasks", "tududi" }, default = { "tasks", "tududi" } },
}

local function notify_error(text)
	hl.notification.create({ text = text, timeout = 10000, color = "rgb(ff5555)" })
end

local ok, local_apps = pcall(require, "local_apps")
if not ok then
	if not tostring(local_apps):find("module 'local_apps' not found", 1, true) then
		notify_error("local_apps.lua: " .. tostring(local_apps))
	end
	local_apps = {}
elseif type(local_apps) ~= "table" then
	notify_error("local_apps.lua must return a table")
	local_apps = {}
end

local function is_installed(app)
	for _, path in ipairs(app.needs) do
		if not file_exists(path) then
			return false
		end
	end
	return true
end

for _, slot in ipairs(app_slots) do
	local conf = local_apps[slot.name]
	local launch = {}
	if conf then
		for _, id in ipairs(conf) do
			if app_catalog[id] then
				table.insert(launch, app_catalog[id])
			else
				notify_error("local_apps.lua: unknown app '" .. id .. "' in " .. slot.name)
			end
		end
	else
		for _, id in ipairs(slot.default) do
			if is_installed(app_catalog[id]) then
				table.insert(launch, app_catalog[id])
			end
		end
	end

	hl.bind("SUPER + ALT + " .. slot.key, function()
		hl.dispatch(hl.dsp.focus({ workspace = slot.workspace, on_current_monitor = true }))
		for _, app in ipairs(launch) do
			if not hl.get_window("class:" .. app.rule) then
				hl.exec_cmd(app.launch)
			end
		end
	end)
	hl.bind("SUPER + ALT + SHIFT + " .. slot.key:lower(), hl.dsp.window.move({ workspace = slot.workspace, follow = false }))

	local members = {}
	for _, id in ipairs(slot.apps) do
		local app = app_catalog[id]
		table.insert(members, app)
		hl.window_rule({
			name = "windowrule-" .. id,
			match = { class = app.rule },
			workspace = tostring(slot.workspace),
		})
	end

	if not conf or conf.group ~= false then
		group_on_open(slot.workspace, function(w)
			for _, app in ipairs(members) do
				for _, pattern in ipairs(app.lua) do
					if w.class:find(pattern) then
						return true
					end
				end
			end
			return false
		end)
	end
end

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
-- Orca (agentic IDE) lives here; sesh-picker raises it by window address
hl.window_rule({
	name = "windowrule-orca",
	match = { class = "^(orca)$" },
	workspace = "60",
})

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
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("qs ipc call osd micMute"), { locked = true, repeating = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs ipc call osd volumeUp"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs ipc call osd volumeDown"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("qs ipc call osd volumeMute"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs ipc call osd brightnessUp"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call osd brightnessDown"))

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
