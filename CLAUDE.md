# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A [chezmoi](https://www.chezmoi.io/) dotfiles repo managing the home directory of an Arch Linux desktop/laptop. Chezmoi translates file names and script prefixes into instructions for how and when to deploy files.

## Instructions

Edit files in this repo and not in their "target locations". For exampe, when asked to to configure anything for neovim edit the nvims in here. After editing a source file, always apply the change. Never run a blanket `chezmoi apply` — always target only the edited file using its home-directory path:

```bash
chezmoi apply ~/.tmux.conf        # example for dot_tmux.conf
chezmoi apply ~/.config/ghostty/config.ghostty
```

## Key chezmoi conventions

| Source name           | Deployed as                                 |
| --------------------- | ------------------------------------------- |
| `dot_foo`             | `~/.foo`                                    |
| `private_dot_foo`     | `~/.foo` (mode 0600)                        |
| `foo.tmpl`            | Go template — rendered before deployment    |
| `run_once_foo.sh`     | Run once ever (state tracked in chezmoi DB) |
| `run_onchange_foo.sh` | Re-run whenever file content changes        |

Templates use `.chezmoi.osRelease.id` (`"arch"`, `"ubuntu"`, etc.) for OS-specific branching and `.chezmoi.hostname` for machine-specific branching (current mapping lives in `.chezmoidata/packages.yaml` under `machines:`).

## Essential commands

```bash
chezmoi apply              # deploy all changes to home dir
chezmoi diff               # preview what apply would change
chezmoi status             # list files with pending changes
chezmoi add ~/.config/foo  # start tracking a new file
chezmoi edit ~/.tmux.conf  # edit source of a managed file, then apply
chezmoi re-add ~/.tmux.conf # sync home → source (after editing live file)
```

To force a `run_once_` script to re-run:

```bash
chezmoi state delete-bucket --bucket=scriptState
```

## Repository layout

- `dot_config/` — XDG config dir (`~/.config/`), containing:
  - `nvim/` — Neovim config (lazy.nvim, selenized theme; plugin loading skipped when running inside VSCode via `vim.fn.exists("g:vscode")`)
  - `hypr/` — Hyprland WM (Lua config since 0.55) split into focused files: `hyprland.lua` (entry, `require`s the others), `keybindings.lua`, `input.lua`, `style.lua`, and `workspaces.lua` (an intentionally empty placeholder kept via the source name `empty_workspaces.lua` so `require("workspaces")` resolves). `hypridle.conf` and `hyprlock.conf` are separate programs and stay in hyprlang format. `monitors.lua` is machine-local and not tracked by chezmoi.
  - `ghostty/config.ghostty` — primary terminal (replaced alacritty)
  - `waybar/`, `swaync/`, `walker/`, `kanata/` — supporting Wayland stack
  - `sesh/sesh.toml` — session manager config; `sesh/scripts/<session-name>.sh` — per-session startup scripts (see below)
- `dot_local/` — `~/.local/` (user binaries, systemd user units, etc.)
- `.chezmoiscripts/` — all `run_once_*` and `run_onchange_*` scripts live here. This is a chezmoi special directory: scripts run as normal, but the directory itself does not create a matching `~/.chezmoiscripts/` in the target. Notable contents:
  - `run_onchange_pacman_installs.sh.tmpl` — renders the pacman install list from `.chezmoidata/packages.yaml`; per-host extras (laptop/pc) are picked via the `machines:` map keyed by `.chezmoi.hostname`
  - `run_onchange_paru_installs.sh.tmpl` — AUR packages (paru), also rendered from `.chezmoidata/packages.yaml`
  - `run_onchange_apt_installs.sh.tmpl` — Debian/Ubuntu installer, rendered from `packages.apt.minimal` in `packages.yaml`. When `aptExtensive = true` is set under `[data]` in `~/.config/chezmoi/chezmoi.toml`, also adds the mise apt repo and installs `packages.apt.extensive` (which includes `mise`). No-op on non-Debian hosts.
  - `run_onchange_npm_global_installs.sh.tmpl` — npm globals from the `npm_global:` list; no-op if npm isn't installed
  - `run_onchange_mise_installs.sh.tmpl` — runs `mise install` for the tools pinned in `dot_config/mise/config.toml` (re-triggers on that file's hash); no-op if mise isn't installed
- `.chezmoidata/packages.yaml` — single source of truth for `pacman`, `paru`, `apt`, and `npm_global` package lists, plus the per-host `machines:` map. Edit this file (not the scripts) to add or remove packages.

## New machine bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:just-barcodes/dotfiles.git
```

Or use `install.sh` if the repo is already cloned locally.
