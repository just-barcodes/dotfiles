-- Walker "sessions" menu: tmux sessions, directories and Orca worktrees.
-- Entries come from the cache that `sesh-picker refresh` maintains; reading a
-- file keeps the menu instant, and each open triggers a background refresh.
-- Open with: walker -m menus:sessions
Name = "sessions"
NamePretty = "Sessions"
Icon = "utilities-terminal"
Description = "tmux sessions, directories and Orca worktrees"
-- Keep the cache order (tmux sessions, sesh sessions, dirs by zoxide score,
-- Orca worktrees) for an empty query instead of alphabetical, so Return
-- without typing lands on a session rather than on "/tmp".
FixedOrder = true
-- Value is the entry name base64-encoded: names contain spaces and parens,
-- and the action string is not shell-quoted by elephant.
Action = "sesh-picker open-b64 %VALUE%"

local function cache_path()
    local dir = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
    return dir .. "/sesh-picker/entries.tsv"
end

local function split_tab(line)
    local fields = {}
    for field in (line .. "\t"):gmatch("([^\t]*)\t") do
        fields[#fields + 1] = field
    end
    return fields
end

-- Pure-Lua base64 so the menu does not fork a process per entry.
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64(s)
    local out = {}
    for i = 1, #s, 3 do
        local a, b, c = s:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
            .. (b and B64:sub(c3 + 1, c3 + 1) or "=")
            .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end

-- Icon per entry kind (column 3 of the cache): icon-theme names, plus Orca's
-- own hicolor icon from the stably-orca-bin package.
ICONS = { tmux = "utilities-terminal", config = "utilities-terminal", orca = "stably-orca",
          zoxide = "folder", default = "utilities-terminal" }

function GetEntries()
    local path = cache_path()
    local f = io.open(path, "r")
    if not f then
        os.execute("sesh-picker refresh >/dev/null 2>&1")
        f = io.open(path, "r")
        if not f then return {} end
    end
    os.execute("setsid -f sesh-picker refresh >/dev/null 2>&1")
    local entries = {}
    for line in f:lines() do
        local c = split_tab(line)
        if c[1] and c[1] ~= "" then
            entries[#entries + 1] = {
                Text = c[1], Subtext = c[2] or "", Value = b64(c[1]),
                Icon = ICONS[c[3]] or ICONS.default,
            }
        end
    end
    f:close()
    return entries
end
