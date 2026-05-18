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

## Install

Pick the one-liner that matches the situation. All three pull this repo to `~/.local/share/chezmoi/` and apply it.

**SSH (preferred — also pulls `dotfiles-private` for secrets/identities; requires an authorized SSH key):**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:just-barcodes/dotfiles.git
```

**HTTPS (no access assumed — public bits only; the private config is silently skipped):**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/just-barcodes/dotfiles.git
```

**HTTPS + extensive apt dev packages (Debian/Ubuntu — adds mise + repo, neovim, db clients, language build deps, network tools, etc. See `packages.apt.extensive` in `.chezmoidata/packages.yaml`):**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init https://github.com/just-barcodes/dotfiles.git \
  && mkdir -p "$HOME/.config/chezmoi" \
  && printf '[data]\n    aptExtensive = true\n' > "$HOME/.config/chezmoi/chezmoi.toml" \
  && "$HOME/.local/bin/chezmoi" apply
```

After install: store the GitHub MCP PAT in the keyring (see below).

`chezmoi init` renders `.chezmoi.toml.tmpl`, which clones `git@github.com:just-barcodes/dotfiles-private.git` to `~/.config/chezmoi-private/` and inlines its `chezmoi.toml` (git identities, etc.) into `~/.config/chezmoi/chezmoi.toml`. Re-run `chezmoi init` to pull updates to the private data.

## Mise-managed dev tools

These dev CLIs are pinned in `dot_config/mise/config.toml` and installed by
`.chezmoiscripts/run_onchange_mise_installs.sh.tmpl` on every `chezmoi apply`
where the config changes: `node`, `kubectl`, `helm`, `argocd`, `terraform`,
`cloudflared`, `direnv`, `opencode`, `task`, `gh`, `lazygit`, `lazydocker`,
`yazi`, `age`, `sops`, `neovim`, `shellcheck`, `bat`, `yq`, `atuin`.

Fast-moving tools (notably `neovim`) live in mise rather than apt/pacman so
they stay current on LTS distros — apt's `neovim` is typically a year+ behind.

`tree-sitter-cli` is the exception: the prebuilt binary requires a recent
glibc and breaks on Debian/Ubuntu LTS. Arch installs it from pacman
(`tree-sitter-cli` in `packages.pacman.developer`); the apt extensive flow
runs `cargo install tree-sitter-cli` so it links the local glibc.

## Mise GitHub token — encrypted-at-rest setup

Mise hits the GitHub releases API to resolve version aliases (`stable`, `latest`) and download binaries. Unauthenticated requests are throttled at 60/hr per IP — easy to exhaust during a fresh install or after a `mise upgrade`. With a token, the limit is 5000/hr.

How the token is stored:

- The PAT lives at `dot_config/secrets/encrypted_private_github.env` in this repo as an **age-encrypted** shell fragment. The ciphertext is safe to commit and push.
- On `chezmoi apply`, it decrypts to `~/.config/secrets/github.env` with mode `0600` using the age key at `~/.config/sops/age/keys.txt`.
- The first line of `~/.zshrc` sources that file, so `$GITHUB_TOKEN` is set before mise's shim path is wired up. Mise reads `GITHUB_TOKEN` from its process env at API-call time (not from its `[env]` table — that table only forwards env to child processes mise launches, not to mise itself).

One-time, per-machine:

1. Add age encryption to `~/.config/chezmoi/chezmoi.toml`:
   ```toml
   encryption = "age"

   [age]
   identity   = "~/.config/sops/age/keys.txt"
   recipients = [
     "age1eegxxwyv0lpdxyl9tlzkeh2l4d8vjq6gg3khzgudahf0x3qf0suqg6eexs",
     "age1wm4vykzkwvajmmphgd38a8pyj070za75kvlpg8kqpela8gtfc4ms4cdst0",
   ]
   ```
   Make sure `~/.config/sops/age/keys.txt` exists and contains a matching private key for at least one recipient.
2. Apply the secrets dir and zshrc so the decrypted file lands at `~/.config/secrets/github.env`:
   ```bash
   chezmoi apply ~/.config/secrets ~/.zshrc
   ```
3. Open a new shell and verify:
   ```bash
   echo "${#GITHUB_TOKEN} chars"        # should print "93 chars" (or 40 for classic PAT)
   mise ls-remote neovim | tail -3      # should print versions, no 403
   ```

To rotate the token (or set it up on a brand-new machine that has the age key but not the encrypted blob yet):

```bash
# In any shell with the age key present:
read -rs T && printf 'export GITHUB_TOKEN=%q\nexport GITHUB_API_TOKEN="$GITHUB_TOKEN"\n' "$T" > /tmp/secrets.env && unset T
chezmoi encrypt < /tmp/secrets.env > ~/.local/share/chezmoi/dot_config/secrets/encrypted_private_github.env
shred -u /tmp/secrets.env
chezmoi apply ~/.config/secrets
```

Generate the token at <https://github.com/settings/tokens> (classic, no scopes needed for public releases) or <https://github.com/settings/personal-access-tokens/new> (fine-grained, public repo read).

**Gotcha — `vfox:` backend does not honour `$GITHUB_TOKEN`.** mise's vfox bridge (`crates/vfox/src/lua_mod/hooks.rs`) makes its own HTTP calls and never injects the auth header, so vfox-backed tools (notably the default `neovim` plugin) keep 403'ing even with a valid token. The aqua backend authenticates correctly. When a tool is available both ways, prefer `aqua:`. That is why `neovim` is pinned as `"aqua:neovim/neovim" = "latest"` rather than `neovim = "stable"`.

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
