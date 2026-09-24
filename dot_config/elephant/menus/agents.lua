-- Walker "agents" menu: live agent sessions tracked by sm, jump with Return.
-- Rows come from `sm-switch.sh list` (sm status is ~3 ms, so no cache).
-- Open with: walker -m menus:agents
Name = "agents"
NamePretty = "Agents"
Icon = "utilities-terminal"
Description = "live agent sessions (sm)"
FixedOrder = true -- sm-switch orders: waiting, idle, running; newest first
Action = "sm focus %VALUE%" -- value is the sm session id (hex)

-- Icons come from `sm-switch.sh list` (column 7): a composite of the agent
-- logo with a host badge (tmux / terminal / Orca), or an icon-theme name.
STATUS = { waiting = "🔴", idle = "🟡", running = "🟢" }

local function split_tab(line)
    local fields = {}
    for field in (line .. "\t"):gmatch("([^\t]*)\t") do
        fields[#fields + 1] = field
    end
    return fields
end

function GetEntries()
    local entries = {}
    local p = io.popen("sm-switch.sh list 2>/dev/null", "r")
    if not p then return entries end
    for line in p:lines() do
        local c = split_tab(line)
        if c[1] and c[1] ~= "" then
            entries[#entries + 1] = {
                Text = (STATUS[c[3]] or "⚪") .. " " .. c[2] .. "  " .. c[4],
                Subtext = c[5] or "",
                Value = c[1],
                Icon = (c[7] ~= nil and c[7] ~= "") and c[7] or "utilities-terminal",
            }
        end
    end
    p:close()
    return entries
end
