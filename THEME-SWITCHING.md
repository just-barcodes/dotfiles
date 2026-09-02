# System-wide theme switching

Plan for a single command that repaints the whole desktop: ghostty, nvim, tmux,
quickshell, hyprland, walker, btop, GTK/Qt apps and Zen. Built so that
light/dark is just the first pair of themes, not the only thing it can do.

Not deployed by chezmoi (listed in `.chezmoiignore`), same as
`QUICKSHELL-MIGRATION.md`.

---

## Status

Verified on `samPC` (Hyprland 0.56.2, Ghostty 1.3.1, Quickshell 0.3.0,
Neovim 0.12.4).

| Phase | State |
| --- | --- |
| 1 — skeleton, portal, ghostty, nvim | **done** (2026-09-02) |
| 2 — quickshell | **done** (2026-09-02) |
| 3 — tmux and hyprland | **done** (2026-09-02) |
| 4 — stragglers, N-theme readiness | **done** (2026-09-02), except hunk — see below |
| 5 — consistency | **done** (2026-09-02) |

### What phase 1 shipped

| File | Role |
| --- | --- |
| `dot_config/theme/palettes/selenized-{dark,light}.env` | the two palettes, 22 colour keys plus `pair`/`polarity`/`gtk_theme` |
| `dot_local/bin/executable_theme-switch` | the switch, ~60 lines |
| `dot_config/ghostty/config.ghostty` | `theme = light:Selenized Light,dark:Selenized Dark` |
| `dot_config/hypr/keybindings.lua` | `CTRL + ALT + SHIFT + T` |
| `dot_config/hypr/hyprland.lua` | `theme-switch apply` in the autostart block |
| `.chezmoiscripts/run_once_setup_dark_theme.sh` | deleted, superseded |

Measured: a toggle takes 0.37s, of which 0.3s is the timeout on one wedged
nvim socket. gsettings costs 13ms and a healthy nvim answers in 6ms.

### What phase 2 shipped

`dot_config/quickshell/Theme.qml` rewritten as two `FileView`s plus an
eight-line parser. All 34 original property names are unchanged, so nothing
else under `dot_config/quickshell/` was touched. Colour properties are now
bindings over the parsed palette, with the previous Selenized Dark literals as
per-key fallbacks, so an unreadable palette leaves the shell looking exactly as
it did before.

Verified: `themeName`, `bg` and `barBg` all update in a **running** shell with
no restart, across repeated switches. Dark-mode values come out byte-identical
to the literals they replace (`bg #103c48`, `barBg #c70d3138`, `surface
#264695f7`), so the switch is visually a no-op in dark.

One palette key was added: `bg_dim` (dark `#0d3138`, light `#ece3cc`). The bar
sits *recessed* from the desktop, and Selenized defines `bg_1`/`bg_2` as raised
with nothing below `bg_0`, so this is the one value `Theme.qml` cannot derive.
This is the "add a key when a consumer needs it" path from
[Adding a theme later](#adding-a-theme-later) working as intended: two lines,
no code change.

### What phase 3 shipped so far

`dot_config/hypr/palette.lua` is new: it reads the state file and the palette,
and exposes `p.rgb(key)` / `p.rgba(key, alpha)` in the `rgba(RRGGBBAA)` form
hyprlang wants. `style.lua` and `hyprland.lua` now call it; all 15 colour
literals are gone. Fallbacks are the Selenized Dark values they replaced.

Two colours changed deliberately in dark mode. `general:col.active_border` was
`#33ccff` and `inactive_border` was `#595959` — both Hyprland stock defaults
that had never been themed. They are now `cyan` and `bg_2`, matching the
groupbar borders that already used those values.

**`hyprctl reload` alone does not work.** See the findings table. The switch
script touches `hyprland.lua` first.

**tmux** required the `envsubst` render pipeline, so that was pulled forward
from phase 4:

- `dot_config/theme/templates/tmux.conf` — one template, every theme. The 37
  colour-bearing lines with each hex replaced by `${key}`.
- `.chezmoiscripts/run_onchange_after_render_themes.sh.tmpl` — renders every
  palette against every template into `~/.config/theme/generated/<name>/`, and
  seeds the `current` symlink if it is missing. Re-triggers on the sha256 of
  any palette or template. `after_` because it reads them from their deployed
  locations.
- `dot_tmux.conf.tmpl` keeps the layout options (position, interval, lengths,
  `pane-border-lines`) and gains an `if-shell`-guarded `source-file` of the
  active theme. The guard matters on a fresh machine, before any switch has run.
- `theme-switch` now repoints `~/.config/theme/current` and re-sources the tmux
  fragment. Every option in it is `set -g`, so one `source-file` repaints all
  sessions on the server.
- `gettext` added to `.chezmoidata/packages.yaml`: `envsubst` was only present
  transitively.

Verified: the rendered dark fragment is byte-identical to the colour lines it
replaced, a **fresh** tmux server picks the theme up at startup, and a switch
repaints a **running** server. Full end-to-end now moves hyprland, tmux, all
four running nvims and gsettings together in 0.41s.

### What phase 4 shipped

| Consumer | How |
| --- | --- |
| ghostty | `config-file = ?../theme/current/ghostty.conf`. Paths are relative to the including file and `?` makes it non-fatal when absent. Replaces the `light:/dark:` shorthand, which can only name one theme per polarity. `theme-switch` sends `SIGUSR2`. |
| btop | `templates/btop.theme` — a real Selenized theme, all 37 keys. `btop.conf` became a `.tmpl` pointing at `~/.config/theme/current/btop.theme`. This also settles the phase-5 item of getting btop off Solarized. |
| walker | Palette split into `templates/walker.css`, imported by `style.css` with a path relative to itself, so no template is needed. `theme-switch` restarts walker, since GTK reads CSS once at startup. |

Walker also had six colour literals sitting *outside* its `@define-color`
block, so it only ever followed the theme halfway — `rgba(173, 188, 188, 0.15)`
is `fg_0`, which is invisible on a light background. Those now go through
`alpha(@accent, …)` / `alpha(@theme_fg_dim, …)`. The two remaining literals are
pure-black drop shadows, which are conventional in both polarities.

**hunk is not wired up.** Its `config.toml` holds nothing but
`theme = "solarized-dark"`, and the plan was to have the switch own that file.
But hunk is an interactive TUI with no `--list-themes` and no theme names in its
binary, so there was no way to confirm a light theme exists without guessing and
risking a broken diff viewer. Left on Solarized Dark. If you know the valid
names, it is a two-line change: a `hunk_theme` key per palette and one more
template.

### What phase 5 shipped

starship moved wholesale to `dot_config/theme/templates/starship.toml`, and
`dot_zshrc.tmpl` exports `STARSHIP_CONFIG` pointing through
`~/.config/theme/current`. starship re-reads its config on every prompt, so a
switch lands on the next prompt in **every** shell, including ones already
open — `theme-switch` sends it nothing at all. The export is guarded so a
machine with no rendered theme falls back to starship's built-in default.

The Gruvbox palette became Selenized, and four literals that bypassed the
palette entirely (`fg:#CC241D` twice, `fg:#83a598` twice) now use palette
colours.

One genuine colour decision: the old palette had a single `color_fg0` used both
on the bright accent chips *and* on the neutral `bg1`/`bg3` chips. That works in
Gruvbox because its accents are mid-tone, but not in Selenized, whose accents
are bright in dark mode. Split into two:

- `color_fg0` = `bg_0` — the maximum-contrast counterpart to an accent in either
  polarity: dark text on bright chips in dark, light text on saturated chips in
  light.
- `color_fg_dim` = `fg_1` — for the neutral chips, where `bg_0` would be
  invisible.

**lazygit, yazi and television needed nothing.** They were listed as unthemed,
but they render through terminal ANSI colours, so they already follow ghostty.
That is why they had no theme set.

Two deviations from the sketch below, both driven by measurement:

- The nvim fan-out is parallel with a 0.3s timeout, not serial at 1s. See the
  `nvim --embed` finding.
- Palettes carry no `name=` key. The filename is the name; a second copy could
  disagree with the file holding it.

---

## Verified findings

These were tested, not assumed. They are the reason the design looks the way it
does.

| Finding | Evidence |
| --- | --- |
| `gsettings set org.gnome.desktop.interface color-scheme` drives the XDG portal | `org.freedesktop.appearance color-scheme` went `1` → `2` → `1` on toggle. `xdg-desktop-portal-gtk` is installed and running. |
| So no D-Bus portal backend needs writing | This is the only hard part of `darkman`. It is unnecessary here. |
| Ghostty reloads on `SIGUSR2` | `strings /usr/bin/ghostty`: `received SIGUSR2, reloading configuration` |
| Ghostty also tracks the portal directly | `strings`: `gtk_ghostty_application: error updating app color scheme` |
| Ghostty supports `config-file` includes, and the include wins over the includer | `ghostty +show-config --default --docs`, `config-file` section |
| Neovim 0.12 opens a socket with no `--listen` flag | 5 live sockets at `$XDG_RUNTIME_DIR/nvim.<pid>.0` |
| Stale nvim sockets hang on connect | `/run/user/1000/nvim.91337.0` (Aug 12, dead server) blocked until killed; 4 others answered instantly |
| Quickshell has no portal or appearance QML type | Installed modules are `Io`, `Services`, `Hyprland`, `Networking`, `Wayland`, `Widgets`, `DBusMenu`, `X11`, `I3`, `WindowManager` |
| Every quickshell colour already goes through `Theme.qml` | 34 properties, zero stray hex literals elsewhere under `dot_config/quickshell/` |
| The Selenized Light palette is already in the repo | `~/.local/share/nvim/lazy/selenized.nvim/colors/selenized.lua:43` has all 24 keys |
| `envsubst` is present | `/usr/bin/envsubst`, owned by `gettext` |

Found while building phase 1:

| Finding | Evidence |
| --- | --- |
| Checking the pid in the socket name does **not** filter stale nvim sockets | `nvim.91337.0` hangs, but pid 91337 is a live `nvim --embed` from Aug 12 whose embedder is gone. It listens and never answers. The timeout is the only reliable guard. |
| A healthy nvim answers `--remote-expr` in ~6ms | So 1s of timeout was 150x more headroom than needed; 0.3s is still 50x |
| The two `gsettings set` calls cost 13ms combined | Not worth optimising |
| `theme = light:X,dark:Y` passes `ghostty +validate-config` | exit 0 |

Found while building phase 2:

| Finding | Evidence |
| --- | --- |
| `FileView.text()` is safe in a binding | `Io/FileView.qml` shows `text()` returning the notifiable `__text`, which is what `Backlight.qml` already relies on |
| `Quickshell.env("HOME")` resolves paths | `stateDir`/`dataDir` are quickshell's own dirs, not the user's |
| Reading a sibling property inside another's change handler returns a **stale** value | `barBg` read from `onBgChanged` lagged one switch; read from `onBarBgChanged` it is always correct. QML does not guarantee binding re-evaluation order within one change cycle, so a change handler is the wrong place to sample sibling properties. |
| Quickshell hot-reloads `Theme.qml` transactionally | `Reloading configuration... Configuration Loaded`, no restart of `qs` needed |

Found while building phase 3:

| Finding | Evidence |
| --- | --- |
| Hyprland's Lua config can `io.open` and `os.getenv` | `palette.lua` reads both files at parse time and the colours land |
| **`hyprctl reload` does not re-execute the Lua config** | After a theme switch it still reported `ee41c7b9`. It re-reads a cached parse, so `palette.lua` never re-runs. This was the phase-3 open question, and the answer is no. |
| `touch` on the entry point *does* trigger a full re-execution | `touch hyprland.lua` alone moved it to `ee009c8f` with no `hyprctl reload` at all — Hyprland watches its config files |
| `touch` causes no chezmoi drift | It changes mtime, not content, so `chezmoi status` stays clean |

The script therefore does `touch hyprland.lua` then `hyprctl reload`: the touch
invalidates the cache, the reload applies it without waiting on the watcher.

Found while building the tmux half of phase 3:

| Finding | Evidence |
| --- | --- |
| `envsubst` must be given an explicit variable list | tmux's `status-format` embeds `awk '/^Mem:/{print $3"/"$2}'`. Bare `envsubst` would eat `$3`/`$2`. With the list built from the palette's own keys they pass through intact. |
| A targeted `chezmoi apply <path>` does not run `.chezmoiscripts` | Scripts have no target path, so the render had to be invoked directly this session. It stays pending in `chezmoi status` until the next full apply, which is harmless: the script is idempotent. |

Found while building phase 4:

| Finding | Evidence |
| --- | --- |
| A palette value containing a space **must** be quoted | `ghostty_theme=Selenized Dark` made `source` try to run `Dark` as a command. Now quoted, and all three parsers strip surrounding quotes. |
| GTK4 accepts `alpha()` inside `@define-color`, and resolves a relative `@import` through the `current` symlink | `Gtk.CssProvider.load_from_path` on the real file reports 0 parsing errors, for both themes |
| btop's `~` question was sidestepped, not answered | The previous value was already an absolute path, so a `.tmpl` is known-good and needed no experiment |
| hunk cannot be probed non-interactively | `hunk diff --theme <bogus>` opens the TUI and blocks rather than erroring |

Found while building phase 5:

| Finding | Evidence |
| --- | --- |
| The explicit envsubst variable list earned its keep again | `starship.toml` is full of `${count}`, `${ahead_count}`, `${behind_count}`. All three survive the render intact. |
| starship needs no signal from `theme-switch` | It re-reads its config per prompt, so the symlink alone is the whole mechanism |
| `starship config` opens an editor, it does not validate | Use `starship prompt` and check the emitted ANSI instead: dark emits `16;60;72`, light `251;243;219`, both exit 0 with no warnings |

### Electron / Obsidian (fixed 2026-09-02)

Obsidian followed dark -> light but then stayed light. Measured with a throwaway
Electron app printing `nativeTheme.shouldUseDarkColors` on every `updated`
event, using the same `electron43` runtime Obsidian ships:

```
UPDATED shouldUseDarkColors=false   <- gsettings color-scheme
UPDATED shouldUseDarkColors=true    <- gsettings gtk-theme, immediately after
```

Each switch was landing the right value and then being overwritten. Chromium
takes the GTK toolkit into account alongside the portal, so setting `gtk-theme`
fires a settings-changed that makes it recompute and discard the portal value
it just accepted.

Removing the `gtk-theme` call fixed it: the probe now alternates cleanly
`false, true, false, true` across four switches with no bounce-back.

Setting `gtk-theme` also bought nothing. kde-gtk-config generates
`~/.config/gtk-3.0/colors.css` from `kdeglobals` and `gtk.css` imports it
unconditionally, so GTK3 resolves the same `#202326` under **both** Breeze and
Breeze-Dark. The theme name cannot change GTK's colours while that import
stands.

Two related cleanups in the same pass:

- `gtk-application-prefer-dark-theme=true` removed from
  `dot_config/gtk-{3,4}.0/private_settings.ini`. It overrode the portal and
  pinned GTK apps dark. Removing it changes nothing visually, because
  `colors.css` wins either way, but it no longer lies about intent.
- Those two files had drifted in the target (breeze cursors, breeze icons,
  `gtk-modules=colorreload-gtk-module`, all written by kde-gtk-config).
  Captured with `chezmoi re-add` before editing, so nothing live was reverted.

**GTK3 apps still do not follow the theme.** They are pinned to the dark
`kdeglobals` palette, which is the behaviour they had before any of this work.
Making them follow means generating `colors.css` per theme from the Selenized
palette through the render pipeline, and giving up the KDE colour integration.
Not done.

Still open:

- hunk's valid theme names (see phase 4).
- GTK3 apps following the theme (see above).

---

## Current state

The stack is not actually on one theme today. Worth fixing as part of this.

| Family | Files |
| --- | --- |
| Selenized Dark | `ghostty/config.ghostty`, `nvim/lua/plugins/selenized.lua`, `quickshell/Theme.qml`, `hypr/style.lua`, `dot_tmux.conf.tmpl`, `walker/themes/minimal/style.css` |
| Solarized Dark | `btop/btop.conf`, `hunk/config.toml` |
| Gruvbox Dark | `starship.toml` |
| Adwaita-dark | `gtk-3.0`, `gtk-4.0`, `run_once_setup_dark_theme.sh`, `private_kdeglobals` |
| Unthemed | `lazygit`, `yazi`, `television`, fzf/bat/delta |

---

## Design

### One rule

**The switch script never writes into a chezmoi-managed file.** No `sed -i` on
`btop.conf` or `config.toml`. That would show as permanent drift in
`chezmoi status` and get reverted on the next apply.

Everything follows from this. chezmoi owns static inputs; the script owns one
state file and one symlink; anything derived is generated into the target tree
by a `run_onchange_` script and is not tracked.

### A theme is one file

A theme is a flat `KEY=value` file. `palette.env`, not JSON, because three
different languages have to read it and only one of them has a JSON parser:

- **shell** sources it directly
- **Lua** (`hypr/style.lua`) parses it with one `gmatch` line
- **QML** (`quickshell/Theme.qml`) parses it with one `split` loop

```sh
# dot_config/theme/palettes/selenized-dark.env
name=selenized-dark
pair=selenized-light       # what `theme-switch toggle` jumps to
polarity=dark              # drives gsettings color-scheme
gtk_theme=Adwaita-dark
ghostty_theme=Selenized Dark
btop_source=/usr/share/btop/themes/solarized_dark.theme
hunk_theme=solarized-dark

bg_0=#103c48
bg_1=#174956
bg_2=#325b66
dim_0=#72898f
fg_0=#adbcbc
fg_1=#cad8d9
red=#fa5750
green=#75b938
yellow=#dbb32d
blue=#4695f7
magenta=#f275be
cyan=#41c7b9
orange=#ed8649
violet=#af88eb
```

The 24 Selenized keys for both dark and light lift straight out of
`selenized.nvim/colors/selenized.lua`. No colour design work required.

### Two kinds of consumer

**Consumers that can parse `palette.env` themselves** read it at runtime and
repaint live. These need no generation step:

- `quickshell/Theme.qml`
- `hypr/style.lua`
- `theme-switch` itself
- nvim, which needs only `polarity` (`set background=`)

**Consumers with a dumb config format** need a rendered fragment. These are
generated once at `chezmoi apply` time by `envsubst` against a template that
lives in the repo exactly once, not once per theme:

- `templates/ghostty.conf` → `theme = ${ghostty_theme}`
- `templates/tmux.conf` → the ~40 status-bar lines, hexes replaced by `${bg_0}` etc.
- `templates/walker.css` → the `@define-color` block
- `templates/btop.theme` → copied from `${btop_source}`, or rendered if we ever
  want a real Selenized btop theme (none is packaged)

### File map

```
SOURCE (chezmoi-managed)
  dot_config/theme/
    palettes/
      selenized-dark.env
      selenized-light.env
    templates/
      ghostty.conf
      tmux.conf
      walker.css
  dot_local/bin/executable_theme-switch
  .chezmoiscripts/run_onchange_render_themes.sh

TARGET (generated or runtime, both untracked)
  ~/.config/theme/palettes/*.env            deployed as-is
  ~/.config/theme/generated/<name>/         rendered by run_onchange
  ~/.config/theme/current -> generated/<name>   symlink, owned by the script
  ~/.local/state/theme                      plain file, holds the theme name
```

Add to `.chezmoiignore`:

```
THEME-SWITCHING.md
.config/theme/generated
.config/theme/current
```

### Why both a symlink and a state file

The symlink is for apps that take a path (`config-file`, `source-file`,
`@import`). The plain state file is for the two watchers.

This matters: `FileView { watchChanges: true }` sets an inotify watch on the
resolved path, so **repointing the `current` symlink will not fire it**. The
state file is rewritten in place on every switch, so it always fires. Quickshell
watches the state file, reads the name, and rebinds a second `FileView` at
`~/.config/theme/palettes/<name>.env`. Four lines of QML, and the palette
survives a `qs` restart because the state is on disk rather than pushed by IPC.

### Wiring per app

| App | Points at | Repaints |
| --- | --- | --- |
| ghostty | `config-file = ~/.config/theme/current/ghostty.conf` | portal, or `pkill -USR2 ghostty` |
| GTK / Qt / Zen / Electron | nothing, the two `gsettings` calls | live |
| nvim | nothing, script pushes over sockets | live |
| quickshell | `Theme.qml` watches `~/.local/state/theme` | live, no restart |
| tmux | `source-file ~/.config/theme/current/tmux.conf` | `tmux source-file` |
| hyprland | `style.lua` reads the state file at parse time | `hyprctl reload` |
| walker | `@import` of `~/.config/theme/current/walker.css` | relaunch (it relaunches constantly) |
| btop | `color_theme = ~/.config/theme/current/btop.theme` | next launch |
| hunk | shell wrapper passing `--theme` | per invocation |

### The script

`dot_local/bin/executable_theme-switch`, about 60 lines:

```sh
#!/usr/bin/env bash
# theme-switch [<name>|toggle|apply|list]
set -uo pipefail

THEMES="$HOME/.config/theme/palettes"
GEN="$HOME/.config/theme/generated"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/theme"

current() { cat "$STATE" 2>/dev/null || echo selenized-dark; }

case "${1:-toggle}" in
    list)   basename -s .env "$THEMES"/*.env; exit 0 ;;
    apply)  name=$(current) ;;                      # called at hyprland start
    toggle) name=$(sed -n 's/^pair=//p' "$THEMES/$(current).env") ;;
    *)      name=$1 ;;
esac

[ -f "$THEMES/$name.env" ] || { echo "no such theme: $name" >&2; exit 1; }
# shellcheck disable=SC1090
. "$THEMES/$name.env"

ln -sfn "$GEN/$name" "$HOME/.config/theme/current"
mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$name" >"$STATE"          # rewritten in place, so inotify fires

gsettings set org.gnome.desktop.interface color-scheme "prefer-$polarity"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

for sock in "$XDG_RUNTIME_DIR"/nvim.*; do
    [ -S "$sock" ] || continue
    timeout 1 nvim --server "$sock" --remote-expr \
        "execute('set background=$polarity | colorscheme selenized')" \
        >/dev/null 2>&1 || true          # timeout is load-bearing, see findings
done

tmux has-session 2>/dev/null &&
    tmux source-file "$HOME/.config/theme/current/tmux.conf" 2>/dev/null || true

hyprctl reload >/dev/null 2>&1 || true
pkill -USR2 -x ghostty 2>/dev/null || true
pkill -x walker 2>/dev/null; walker --gapplication-service & disown
```

Bind in `dot_config/hypr/keybindings.lua` next to the existing `sm-switch.sh`
bind, and add `hl.exec_cmd("theme-switch apply")` to the
`hl.on("hyprland.start")` block in `hyprland.lua` so a fresh session restores
the saved theme.

---

## Adding a theme later

This is the whole procedure. One new file, no code changes:

1. `cp dot_config/theme/palettes/selenized-dark.env dot_config/theme/palettes/gruvbox-dark.env`
2. Fill in the 24 colour keys and the 7 metadata keys. Set `pair=` on both
   halves of a light/dark couple so `toggle` moves between them.
3. `chezmoi apply ~/.config/theme` — `run_onchange_render_themes.sh` re-runs
   because the palette hash changed, and renders `generated/gruvbox-dark/`.
4. `theme-switch gruvbox-dark`

`theme-switch list` enumerates whatever is in `palettes/`.

**Adding a new themed app** is the only thing that costs more. Either it can
parse `palette.env` (add a reader, like quickshell and hyprland have) or it
cannot (add one file to `templates/`, which then applies to every existing theme
at once). Both are additive. No theme file changes.

Deliberately **not** built:

- Scheduling or geoclue. Out of scope, and `darkman` is a one-line install if
  that ever changes.
- A D-Bus interface. Nothing in this stack would subscribe to it.
- A hook directory (`~/.local/share/{dark,light}-mode.d/`). There are eight
  fixed apps; the indirection buys nothing.

---

## Phases

Each phase is independently useful and independently verifiable.

### Phase 1 — skeleton, portal, ghostty, nvim

1. `palettes/selenized-{dark,light}.env` with colours copied from
   `selenized.nvim/colors/selenized.lua`.
2. `theme-switch` with the state file, gsettings, and the nvim fan-out.
3. Ghostty: `theme = light:Selenized Light,dark:Selenized Dark`. Use the
   polarity form for now; phase 4 moves it to a `config-file` include once
   there is more than one dark theme to choose between.
4. Retire `run_once_setup_dark_theme.sh`, which hardcodes `prefer-dark`.

Verify: `theme-switch toggle` repaints ghostty and every GTK app, and flips
every running nvim including ones inside tmux. Confirm whether ghostty needed
the `SIGUSR2`.

### Phase 2 — quickshell

Rewrite `Theme.qml` as two `FileView`s plus a parser, keeping all 34 property
names so nothing else under `dot_config/quickshell/` changes. Colour properties
become bindings on the parsed map with the current dark values as fallbacks.

Verify: bar, control center, OSD and notification popups recolour with `qs`
still running. Restart `qs` and confirm it comes back on the saved theme.

### Phase 3 — tmux and hyprland

Extract the ~40 hexes from `dot_tmux.conf.tmpl` into `templates/tmux.conf` and
add the `source-file`. Add the `palette.env` reader to `style.lua` and replace
the inline `rgba()` literals, including the `special-magic-border` window rule
in `hyprland.lua`.

Verify: toggle with a tmux session and a tiled window visible. Confirm
`hyprctl reload` actually re-executes the Lua.

### Phase 4 — the stragglers, and N-theme readiness

walker CSS split, btop symlink, hunk wrapper. Move ghostty from the
`light:/dark:` shorthand to the `config-file` include, because the shorthand can
only express one dark and one light theme and cannot pick between
`selenized-dark` and a future `gruvbox-dark`.

Add `gettext` to `.chezmoidata/packages.yaml`. It is present but only as a
transitive dependency, and `run_onchange_render_themes.sh` needs `envsubst`.

### Phase 5 — consistency

Bring `btop`, `hunk` and `starship` onto Selenized so "theme" means one thing.
Optionally theme `lazygit`, `yazi` and `television`, which are currently on
defaults.

---

## Gotchas

1. **Stale nvim sockets block.** Verified. `timeout 1` and `|| true` are required,
   not defensive padding.
2. **Symlink flips do not fire inotify.** Hence the separate state file for
   quickshell. Same applies to any future `FileView` watcher.
3. **Login is a different path from toggle.** Quickshell and hyprland read the
   state file themselves at startup and self-resolve. gsettings and the symlink
   do not, hence `theme-switch apply` in the hyprland autostart block.
4. **btop is long-lived.** It is launched into workspace 99 at hyprland start and
   will stay stale until relaunched. Either kill and respawn it in the script or
   accept it.
5. **gsettings needs the session bus.** Fine from a hyprland keybind, which
   inherits it. Would not be fine from a systemd unit without
   `--user` and the right environment. See the GUI-session PATH note: uwsm
   sources `dot_profile`, so `theme-switch` must be reachable from there.
6. **walker's `style.css` must become a `.tmpl`** if the `@import` needs an
   absolute path, since GTK CSS has no `~` expansion. Relative
   (`../../../theme/current/walker.css`) works but reads badly.
7. **`hyprlock.conf` looks dead.** `Lock.qml` replaced it and `hypridle.conf`
   calls `qs ipc call lock lock`. Confirm before spending time theming it.
8. **`dot_config/swaync/` is still tracked** despite the quickshell migration.
   Unrelated to this work, flagged only so it is not themed by mistake.

---

## Cost

Roughly 60 lines of shell, 40 lines of QML, 25 lines of Lua, and ~150 lines of
palette and template data split across six files. Two to three hours, and the
largest single chunk is the mechanical hex-for-hex tmux rewrite.

For comparison: doing this on top of `darkman` instead differs by about 40 lines
of shell. Every palette extraction above is identical either way, because
darkman's hooks would run the same `tmux source-file` and nvim fan-out. The
dependency would buy scheduling that is out of scope and a portal backend that
gsettings already provides.
