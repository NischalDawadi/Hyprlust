# dotfiles — Hyprlust, fish edition

Arch Linux installer + fish shell config for
[NischalDawadi/Hyprlust](https://github.com/NischalDawadi/Hyprlust), converted
from zsh to fish.

## Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ro3in/dotfiles/main/install.sh)"
```

Preview what it will do without changing anything:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ro3in/dotfiles/main/install.sh)" -- --dry-run
```

## What it does

1. Checks you are a normal user on an Arch-based system with `sudo`.
2. Installs the official-repo packages Hyprlust actually needs.
3. Installs an AUR helper (yay) if you have neither yay nor paru, then the
   optional AUR packages (pyprland, wallust, wlogout, …).
4. Clones upstream Hyprlust and this repo.
5. Deploys `config.fish` plus the desktop configs, backing up anything it
   replaces to `~/.config-backup-<timestamp>/`.
6. Repairs the broken absolute symlinks upstream ships.
7. Adapts Hyprlust's `swww` calls to `awww`.
8. Rewrites hardcoded `/home/hypr` paths to your `$HOME`.
9. Enables NetworkManager and Bluetooth, offers to switch your shell to fish.

## Differences from upstream

| | upstream Hyprlust | this fork |
|---|---|---|
| Shell | zsh + oh-my-zsh | **fish** (native syntax, fisher plugins) |
| Wallpaper daemon | `swww` | `awww` (swww's successor), scripts patched |
| Config deployment | copies all 128 MB of `~/.config` | only desktop configs, no app caches |
| Broken symlinks | `waybar/config` → `/home/hypr/...` | repaired to real in-repo files |
| Hardcoded paths | `/home/hypr` | rewritten to `$HOME` |

## Requirements

- Arch Linux or an Arch-based distro (EndeavourOS, CachyOS, …)
- A regular user with sudo
- An existing booting system — this is not a bootstrapper

## Notes

- **NVIDIA**: the installer detects your GPU and prints what to do. Install
  `nvidia-dkms nvidia-utils libva-nvidia-driver`, then uncomment the NVIDIA
  block in `~/.config/hypr/UserConfigs/ENVariables.conf`.
- **Wallpapers** live in a separate 450 MB repo and are not downloaded
  automatically. `git clone --depth=1 https://github.com/NischalDawadi/Wallpapers ~/Pictures/wallpapers`
- **Monitor config**: edit `~/.config/hypr/UserConfigs/Monitors.conf` before
  your first login.
- Not installed on purpose: spicetify, Seanime, Upscayl (app state, ~100 MB),
  and `ags` (a leftover `exec-once` line upstream; the waybar bar is the one
  actually used).
