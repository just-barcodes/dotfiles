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
| Bootloader       | systemd-boot, unified kernel images on                      |
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
laptops), installs a default-drop inbound firewall (nftables), sets up snapper
on a btrfs root, unlocks the keyring at login, and renders the themes.
Run it as your user, never with sudo. If a script fails, fix the cause and re-run
`chezmoi apply`; do not reset chezmoi's script state as a first step.

## 5. Shell and sanity check

```bash
chsh -s /usr/bin/zsh
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

## 8. Secure Boot and TPM unlock (laptop, after the first successful boot)

Encryption alone does not protect the unsigned kernel and loader on the EFI
partition. `sbctl` signs them with your own keys; the TPM then releases the
LUKS key only when the boot chain is unchanged, so the passphrase prompt goes
away. Keep the passphrase slot as fallback.

Setup mode has to be enabled in the UEFI firmware first; it cannot be done
from Linux. Reboot into firmware setup (`systemctl reboot --firmware-setup`),
find the Secure Boot section (usually under Security or Boot) and clear or
delete the existing keys ("Clear Secure Boot keys", "Reset to Setup Mode",
"Delete all Secure Boot variables"; some firmwares expose it under
"Secure Boot Mode: Custom"). Leave Secure Boot itself enabled. If the option is
missing, setting a supervisor password usually unlocks the submenu. After
rebooting, `sbctl status` should show `Setup Mode: Enabled` and
`Secure Boot: Disabled`; the latter flips to enabled once keys are enrolled and
the binaries are signed.

```bash
sudo pacman -S --needed sbctl
sudo sbctl status                       # expect Setup Mode: Enabled
sudo sbctl create-keys && sudo sbctl enroll-keys -m
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
sudo sbctl sign -s /boot/EFI/Linux/arch-linux.efi   # the UKI; -s makes the pacman hook re-sign it
sudo sbctl verify && reboot             # then confirm: bootctl status shows Secure Boot: enabled
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/<luks-partition>
```

The kernel command line is baked into the UKI from `/etc/kernel/cmdline`
(there are no `/boot/loader/entries/*.conf`). Add
`rd.luks.options=tpm2-device=auto` there and run `sudo mkinitcpio -P` to
rebuild the UKI; the sbctl hook re-signs it. A firmware update changes PCR 7;
re-run the `cryptenroll` line with `--wipe-slot=tpm2` first.

## 9. DNS

**Machines in the tailnet.** DNS policy lives in the Tailscale admin console,
not on the machine: DNS → Nameservers → AdGuard Home's Tailscale IP, with
"Override local DNS" on. AdGuard Home carries the encrypted upstreams. Then:

```bash
sudo tailscale set --accept-dns=true
tailscale dns status
```

**Machines outside the tailnet** (work laptops) get AdGuard from DHCP at home
and nothing elsewhere. For an encrypted, filtered resolver everywhere:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nDNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net\nDNSOverTLS=yes\n' | sudo tee /etc/systemd/resolved.conf.d/dot.conf
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

Quad9 blocks malware domains only, not ads; the AdGuard Home rules apply
only inside the tailnet.

## 10. Backups

Snapshots are not backups. Point restic or borg at `~` and a remote target
before relying on the machine.

## 11. Secrets and private config (optional, any time later)

1. Put an SSH key on GitHub, then switch the source to SSH and re-init so the
   private companion repo gets pulled:
   `git -C "$(chezmoi source-path)" remote set-url origin git@github.com:just-barcodes/dotfiles.git && chezmoi init`
2. Age key + GitHub token for mise: README, "Mise GitHub token".
3. GitHub MCP PAT in the keyring: README, "Claude Code GitHub MCP".

## Maintenance

```bash
sudo pacman -Syu && sudo pacdiff     # upgrade, then merge any /etc/*.pacnew
chezmoi update                       # pull the repo and apply
pkgpick --drift                      # explicit packages missing from both lists
```

Unmerged `.pacnew` files silently keep old mirrorlists, locales and PAM
defaults; `pacdiff` needs `DIFFPROG=nvim` or similar in the environment.

## Known gaps (not automated yet)

- Monitor layout is machine-local: create `~/.config/hypr/monitors.lua` by hand.
- kanata's user unit needs the `input` and `uinput` groups plus a udev rule;
  the repo ships neither.
- Firewall: inbound is dropped by default. Ports a machine must expose go in
  `/etc/nftables.d/local.nft`, then `sudo systemctl reload nftables`.
