-- Walker "packages" menu: optional packages from .chezmoidata/packages.yaml
-- that are not installed. Listed in walker's default providers, so typing a
-- package name in the launcher (ALT+space) offers to install it; Return opens
-- a terminal running `pkgpick install <pkg>`, and paru asks before installing.
-- The yaml is parsed here (not via `chezmoi data`) to keep the `# comment`
-- after each package as the subtext.
Name = "packages"
NamePretty = "Install"
Icon = "system-software-install"
Description = "optional packages not installed yet"
HideFromProviderlist = true
Terminal = true
Action = "pkgpick install %VALUE%"

local YAML = os.getenv("HOME") .. "/.local/share/chezmoi/.chezmoidata/packages.yaml"

local function installed_set()
    local set = {}
    local p = io.popen("pacman -Qq 2>/dev/null", "r")
    if not p then return set end
    for line in p:lines() do set[line] = true end
    p:close()
    return set
end

function GetEntries()
    local entries = {}
    local f = io.open(YAML, "r")
    if not f then return entries end
    local installed = installed_set()
    -- path[indent] = key, so a "- item" line at indent 8 belongs to
    -- path[0]/path[2]/path[4]/path[6] (packages/optional/<manager>/<group>).
    local path = {}
    for line in f:lines() do
        local indent, body = line:match("^(%s*)(.-)%s*$")
        if body ~= "" and body:sub(1, 1) ~= "#" then
            local n = #indent
            local key = body:match("^([%w_%-]+):")
            if key then
                path[n] = key
                for k in pairs(path) do if k > n then path[k] = nil end end
            elseif path[0] == "packages" and path[2] == "optional" and n == 8 then
                local pkg, desc = body:match("^%- ([^%s#]+)%s*#?%s*(.*)$")
                if pkg and not installed[pkg] then
                    local group = path[6] or ""
                    entries[#entries + 1] = {
                        Text = pkg,
                        Subtext = (desc ~= "" and desc or group) .. "  [" .. path[4] .. "/" .. group .. "]",
                        Value = pkg,
                        Icon = "system-software-install",
                        Keywords = { group },
                    }
                end
            end
        end
    end
    f:close()
    return entries
end
