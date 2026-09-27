# Bootstrapping a new Arch machine

Two layers: `archinstall` gives you a bootable, encrypted base system; this repo
turns it into the Hyprland desktop. Nothing in `chezmoi apply` touches disks or
the bootloader.

## 1. Install Arch (from the live ISO)

```bash
test -d /sys/firmware/efi/efivars || echo "STOP: not UEFI"
loadkeys us                      # console layout for the LUKS passphrase
iwctl                            # wifi: station wlan0 connect "<ssid>"; skip on ethernet
archinstall
```

In the installer:

| Setting          | Pick                                                        |
| ---------------- | ----------------------------------------------------------- |
| Disk             | the internal SSD only, best-effort layout, **btrfs**, subvolumes, compression |
| Encryption       | LUKS on the Linux partition                                 |
| Bootloader       | systemd-boot                                                |
| Kernel           | linux                                                       |
| Profile          | Minimal                                                     |
| Network          | NetworkManager                                              |
| Audio            | pipewire                                                    |
| Swap             | zram                                                        |
| Hostname         | anything; the package profile is chosen in step 3           |
| User             | your normal user, sudo                                      |
| Extra packages   | `git chezmoi base-devel`                                    |

Reboot into the new system and log in on the TTY.

## 2. Bootstrap dependencies

Everything else comes from the repo's package scripts, which run first.

```bash
sudo pacman -Syu --needed git chezmoi
```

## 3. Init the repo (no SSH key yet, so HTTPS)

```bash
chezmoi init https://github.com/just-barcodes/dotfiles.git
```

It asks once for the machine type; answer `laptop` or `desktop`. That selects
the profile in `.chezmoidata/packages.yaml`: laptop adds `sof-firmware`,
`fprintd` and `power-profiles-daemon`; desktop adds GRUB. Non-interactive:
`chezmoi init --promptChoice "Machine type=laptop" <url>`.

If the keyboard is not `us`, edit `kb_layout` in
`$(chezmoi source-path)/dot_config/hypr/input.lua` now.

## 4. Apply

```bash
chezmoi diff | less     # optional sanity check
sudo -v
chezmoi apply -v
```

This installs `packages.core` (pacman, then paru from the AUR), the mise tools,
writes the greetd config, enables greetd, NetworkManager, bluetooth, the
fstrim, paccache and fwupd-refresh timers (plus power-profiles-daemon on
laptops), and renders the themes.
Run it as your user, never with sudo. If a script fails, fix the cause and re-run
`chezmoi apply`; do not reset chezmoi's script state as a first step.

## 5. Shell and sanity check

```bash
chsh -s /usr/bin/zsh
xdg-user-dirs-update
systemctl --failed; systemctl is-enabled greetd
reboot
```

## 6. First graphical login

greetd (tuigreet) starts Hyprland through uwsm. Check `hyprctl configerrors`.
Then pick the rest:

```bash
pkgpick      # browser, dolphin, pavucontrol, tailscale, intel-gpu group, ...
misepick     # extra dev CLIs
```

If the session does not start: `Ctrl+Alt+F3`, then
`journalctl -b -u greetd` and `journalctl --user -b -p warning`.

## 7. Mirrors (optional)

`reflector` is in core but its timer is not enabled, because it rewrites
`/etc/pacman.d/mirrorlist` on its own schedule. To let it, set the countries
in `/etc/xdg/reflector/reflector.conf` (the default is the 5 freshest mirrors
worldwide) and enable it:

```bash
sudo reflector --country Switzerland,Germany --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
sudo systemctl enable --now reflector.timer   # weekly, uses the .conf, not the flags above
```

## 8. Secrets and private config (optional, any time later)

1. Put an SSH key on GitHub, then switch the source to SSH and re-init so the
   private companion repo gets pulled:
   `git -C "$(chezmoi source-path)" remote set-url origin git@github.com:just-barcodes/dotfiles.git && chezmoi init`
2. Age key + GitHub token for mise: README, "Mise GitHub token".
3. GitHub MCP PAT in the keyring: README, "Claude Code GitHub MCP".

## Known gaps (not automated yet)

- Monitor layout is machine-local: create `~/.config/hypr/monitors.lua` by hand.
- kanata's user unit needs the `input` and `uinput` groups plus a udev rule;
  the repo ships neither.
- gnome-keyring is not unlocked by greetd's PAM stack, so `secret-tool`
  prompts on first use.
