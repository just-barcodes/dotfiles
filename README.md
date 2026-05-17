# chezmoi

# TODO

sudo systemctl enable --now chronyd
sudo systemctl enable --now bluetooth
sudo systemctl enable --now greetd
sudo systemctl enable --now power-profiles-daemon

`/etc/greetd/config.toml`:

```bash
[terminal]
# The VT to run the greeter on. Can be "next", "current" or a number
# designating the VT.
vt = 1

# The default session, also known as the greeter.
[default_session]

# `agreety` is the bundled agetty/login-lookalike. You can replace `/bin/sh`
# with whatever you want started, such as `sway`.
command = "tuigreet --cmd start-hyprland"

# The user to run the command as. The privileges this user must have depends
# on the greeter. A graphical greeter may for example require the user to be
# in the `video` group.
user = "greeter"
```

## For completely new installation

1. Set up ssh keys (give access to `dotfiles-private`)
2. Run this command to install chezmoi and dotfiles: `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:just-barcodes/dotfiles.git`
3. Store the GitHub MCP PAT in the keyring (see below)

`chezmoi init` renders `.chezmoi.toml.tmpl`, which clones `git@github.com:just-barcodes/dotfiles-private.git` to `~/.config/chezmoi-private/` and inlines its `chezmoi.toml` (git identities, etc.) into `~/.config/chezmoi/chezmoi.toml`. Re-run `chezmoi init` to pull updates to the private data.

## Mise-managed dev tools

These dev CLIs are pinned in `dot_config/mise/config.toml` and installed by
`.chezmoiscripts/run_onchange_mise_installs.sh.tmpl` on every `chezmoi apply`
where the config changes: `node`, `kubectl`, `helm`, `argocd`, `terraform`,
`cloudflared`, `direnv`, `tree-sitter`, `opencode`, `task`, `gh`, `lazygit`,
`lazydocker`, `yazi`, `age`, `sops`.

## Claude Code GitHub MCP — PAT setup

The GitHub MCP server (`api.githubcopilot.com/mcp`) uses a Personal Access Token instead of OAuth. The token is stored in gnome-keyring via `secret-tool`; `~/.zshrc` exports it as `$GITHUB_PAT` at shell startup, and `.chezmoiscripts/run_onchange_claude_mcp_servers.sh` registers the server with a literal `${GITHUB_PAT}` placeholder that Claude Code expands at runtime. Nothing sensitive is written to `~/.claude.json` or the repo.

One-time, per-machine:

1. Create a fine-grained PAT at <https://github.com/settings/personal-access-tokens/new>.
   Suggested permissions: Contents (R/W), Issues (R/W), Pull requests (R/W), Metadata (R) — scope to the repos you want Claude to touch.
2. Store it in the keyring (prompts for the token value):
   ```bash
   secret-tool store --label='GitHub MCP PAT' service github-mcp
   ```
3. Open a new shell so `$GITHUB_PAT` is set, then verify:
   ```bash
   claude mcp list   # github should show ✓ Connected
   ```

If the MCP entry drifts (wrong URL/header) after editing the chezmoi script, re-running `chezmoi apply` re-executes the onchange script, which removes and re-adds the `github` entry.
