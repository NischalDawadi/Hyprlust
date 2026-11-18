#!/usr/bin/env bash
#
# install.sh — Arch Linux installer for the Hyprlust dotfiles (fish edition)
#
# Upstream:  https://github.com/NischalDawadi/Hyprlust   (zsh)
# This fork: https://github.com/ro3in/dotfiles            (fish)
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/ro3in/dotfiles/main/install.sh)"
#
# Or, after cloning:
#   ./install.sh            # full install
#   ./install.sh --dry-run  # show what would happen, change nothing
#
# What this does NOT do: repartition, install a bootloader, or create users.
# Run it on an Arch/Arch-based system that already boots and has a user.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# Your fork of Hyprlust. It holds the whole config tree, the fish config and
# this installer, so a single clone is all that is needed.
REPO_URL="${REPO_URL:-https://github.com/ro3in/Hyprlust.git}"

REPO_DIR="${REPO_DIR:-$HOME/Hyprlust}"   # where the dotfiles get cloned
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
    C_OK=$'\033[0;32m'; C_WARN=$'\033[1;33m'; C_INFO=$'\033[0;34m'
    C_ERR=$'\033[0;31m'; C_OFF=$'\033[0m'
else
    C_OK=""; C_WARN=""; C_INFO=""; C_ERR=""; C_OFF=""
fi

info() { printf '%s[INFO]%s %s\n' "$C_INFO" "$C_OFF" "$*"; }
ok()   { printf '%s[ OK ]%s %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$C_WARN" "$C_OFF" "$*" >&2; }
die()  { printf '%s[FAIL]%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }

run() {
    if (( DRY_RUN )); then
        printf '  + %s\n' "$*"
    else
        "$@"
    fi
}

# Make sure a directory is on PATH for fish sessions.
ensure_path_line() {
    local dir="$1"
    local conf="$HOME/.config/fish/config.fish"
    [[ -d "$dir" ]] || return 0
    grep -qsF "$dir" "$conf" && return 0
    (( DRY_RUN )) && { printf '  + add %s to fish PATH\n' "$dir"; return 0; }
    printf '\nfish_add_path --global %s\n' "$dir" >>"$conf"
}

# ---------------------------------------------------------------------------
# 1. Preflight
# ---------------------------------------------------------------------------
(( EUID == 0 )) && die "Run as your normal user, not root (the script calls sudo itself)."

command -v pacman >/dev/null || die "pacman not found — this installer is for Arch Linux only."
command -v sudo   >/dev/null || die "sudo not found — install sudo and add your user to the wheel group."

# Keep sudo alive for the whole run instead of re-prompting mid-install.
# A dry run changes nothing, so it must not ask for a password at all.
# The keepalive loop closes its inherited stdout/stderr; otherwise it holds the
# caller's pipe open and `curl | bash` appears to hang after the script ends.
if (( DRY_RUN )); then
    SUDO_KEEPALIVE_PID=""
else
    info "Requesting sudo privileges..."
    sudo -v || die "sudo authentication failed."
    (
        while kill -0 "$$" 2>/dev/null; do
            sudo -n true
            sleep 50
        done
    ) >/dev/null 2>&1 &
    SUDO_KEEPALIVE_PID=$!
fi
trap '[[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

info "Arch-based system detected: $(. /etc/os-release && printf '%s' "${PRETTY_NAME:-unknown}")"
(( DRY_RUN )) && warn "DRY RUN — nothing will be installed or modified."

# Detect NVIDIA early: Hyprland needs different env vars on Team Green.
GPU_NVIDIA=0
if command -v lspci >/dev/null && lspci 2>/dev/null | grep -qi 'nvidia'; then
    GPU_NVIDIA=1
fi

# ---------------------------------------------------------------------------
# 2. Packages
# ---------------------------------------------------------------------------
# Official repos only. Everything here is required by Hyprlust's configs:
# the hyprland.conf sources, waybar's custom modules, and the Keybinds.
PACMAN_PKGS=(
    # --- Hyprland core ---
    hyprland hyprland-protocols hyprpm hyprlock hypridle hyprpicker
    hyprpolkitagent hyprsunset
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils
    polkit polkit-gnome qt5-wayland qt6-wayland

    # --- Bar, launcher, notifications, wallpaper ---
    waybar rofi kitty swaync awww swaybg
    # NOTE: awww is the renamed successor of swww and PROVIDES/REPLACES it.

    # --- Screenshots & clipboard ---
    grim slurp swappy wl-clipboard cliphist

    # --- Audio / media / brightness ---
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
    pamixer pavucontrol playerctl brightnessctl
    mpd mpc rmpc cava

    # --- Networking & Bluetooth ---
    networkmanager network-manager-applet bluez bluez-utils blueman

    # --- File manager, archives, images ---
    thunar thunar-archive-plugin file-roller tumbler gvfs
    imagemagick ffmpeg

    # --- Fonts (waybar/kitty reference these by name) ---
    ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-iosevka-nerd
    otf-font-awesome ttf-nerd-fonts-symbols inter-font
    noto-fonts noto-fonts-emoji

    # --- Theming ---
    nwg-look qt5ct qt6ct kvantum kvantum-qt5
    materia-gtk-theme papirus-icon-theme gnome-themes-extra
    dconf

    # --- Shell & CLI (fish instead of zsh) ---
    fish fisher starship fastfetch btop eza zoxide fzf bat
    yazi neovim mpv zathura jq python python-pyquery python-requests
    rsync curl wget unzip git base-devel
)

# AUR packages. Optional: the desktop still works without them, but you lose
# pyprland's dropdown terminal, wallust recolouring, and the GTK shell.
AUR_PKGS=(
    pyprland              # SUPER+SHIFT+Return dropdown terminal
    wallust               # recolours kitty/waybar/swaync from the wallpaper
    wlogout               # power menu (CTRL+ALT+P)
    sptlrx                # spotify lyrics in the bar
    bibata-cursor-theme-bin
    tela-circle-icon-theme-git
    iio-hyprland-git      # autorotate on tablets/laptops
)

info "Installing packages from the official repos..."
run sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"
ok "Official packages installed."

# --- AUR helper -------------------------------------------------------------
AUR_HELPER=""
if command -v paru >/dev/null; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null; then
    AUR_HELPER="yay"
else
    info "No AUR helper found — building yay from source..."
    if (( DRY_RUN )); then
        printf '  + git clone https://aur.archlinux.org/yay-bin.git && makepkg -si\n'
        AUR_HELPER="yay"
    else
        _tmp="$(mktemp -d)"
        if git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$_tmp/yay-bin" \
            && ( cd "$_tmp/yay-bin" && makepkg -si --noconfirm ); then
            AUR_HELPER="yay"
            ok "yay installed."
        else
            warn "Could not install yay. Skipping AUR packages."
        fi
        rm -rf "$_tmp"
    fi
fi

if [[ -n "$AUR_HELPER" ]]; then
    info "Installing AUR packages with $AUR_HELPER..."
    for pkg in "${AUR_PKGS[@]}"; do
        if run "$AUR_HELPER" -S --needed --noconfirm "$pkg"; then
            :
        else
            warn "AUR package '$pkg' failed — continuing without it."
        fi
    done
fi

# ---------------------------------------------------------------------------
# 3. Fetch the dotfiles
# ---------------------------------------------------------------------------
clone_or_update() {
    local url="$1" dest="$2" label="$3"
    if [[ -d "$dest/.git" ]]; then
        info "Updating $label in $dest..."
        run git -C "$dest" pull --ff-only || warn "Could not update $label — using the local copy."
    elif [[ -e "$dest" ]]; then
        # A leftover non-git directory (older manual clone, partial download)
        # would otherwise abort the whole install. Move it aside and re-clone.
        warn "$dest exists but is not a git checkout — moving it aside."
        run mv "$dest" "${dest}.bak-$(date +%Y%m%d-%H%M%S)"
        info "Cloning $label into $dest..."
        run git clone --depth=1 "$url" "$dest"
    else
        info "Cloning $label into $dest..."
        run git clone --depth=1 "$url" "$dest"
    fi
}

clone_or_update "$REPO_URL" "$REPO_DIR" "Hyprlust (ro3in fork)"

if [[ ! -d "$REPO_DIR/.config/hypr" ]]; then
    die "$REPO_DIR does not look like a Hyprlust checkout (no .config/hypr)."
fi

# ---------------------------------------------------------------------------
# 4. Deploy the fish shell config
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.config/fish"
FISH_CONFIG="$HOME/.config/fish/config.fish"

# Take the fork's config.fish if present, otherwise keep whatever is there.
FORK_FISH="$REPO_DIR/.config/fish/config.fish"
if [[ -f "$FORK_FISH" ]]; then
    if [[ -f "$FISH_CONFIG" ]] && ! cmp -s "$FORK_FISH" "$FISH_CONFIG"; then
        mkdir -p "$BACKUP_DIR/fish"
        run cp -a "$FISH_CONFIG" "$BACKUP_DIR/fish/config.fish"
        info "Backed up the existing fish config."
    fi
    run install -Dm644 "$FORK_FISH" "$FISH_CONFIG"
    ok "Deployed fish config from this fork."
elif [[ ! -f "$FISH_CONFIG" ]]; then
    # The fork was unreachable AND this machine has no fish config yet.
    # Write a minimal but usable one rather than leaving fish bare.
    warn "Fork unavailable and no existing fish config — writing a minimal one."
    if (( DRY_RUN )); then
        printf '  + write a minimal %s\n' "$FISH_CONFIG"
    else
        cat >"$FISH_CONFIG" <<'EOF'
# Minimal fish config written by install.sh (Hyprlust)
set -gx EDITOR nvim
fish_add_path --global $HOME/.local/bin $HOME/.cargo/bin $HOME/.bun/bin

if status is-interactive
    type -q starship && starship init fish | source
    type -q zoxide && zoxide init fish | source
    type -q fzf && fzf --fish 2>/dev/null | source
end
EOF
    fi
else
    info "Using the existing fish config at $FISH_CONFIG."
fi

# Starship must be initialised for fish. Only add it if it is really missing.
if ! grep -qs 'starship init fish' "$FISH_CONFIG"; then
    if (( DRY_RUN )); then
        printf '  + append starship init to %s\n' "$FISH_CONFIG"
    else
        cat >>"$FISH_CONFIG" <<'EOF'

# Added by install.sh (Hyprlust fish port)
if status is-interactive
    starship init fish | source
end
EOF
    fi
fi

# ---------------------------------------------------------------------------
# 5. Deploy the Hyprlust config tree
# ---------------------------------------------------------------------------
# Upstream is a full ~/.config dump, 128 MB of which ~92 MB is a spicetify
# cache and app databases. Copying all of it onto every machine is wasteful and
# drags along per-machine state (browser profiles, logs, .db files).
# Deploy only what actually themes the desktop.
CONFIG_ITEMS=(
    hypr waybar kitty rofi swaync wlogout
    gtk-2.0 gtk-3.0 gtk-4.0 Kvantum qt5ct qt6ct nwg-look
    btop fastfetch cava starship.toml
    # Optional extras — deployed only if you have the apps installed.
    mpd rmpc mpv nvim yazi zathura swappy wallust matugen
)

backup_and_place() {
    local src="$1" dest="$2"
    if [[ -e "$dest" || -L "$dest" ]]; then
        mkdir -p "$BACKUP_DIR/$(dirname "${dest#"$HOME"/}")"
        run mv "$dest" "$BACKUP_DIR/${dest#"$HOME"/}"
    fi
    run cp -a "$src" "$dest"
}

info "Deploying desktop configs (existing ones go to $BACKUP_DIR)..."
for item in "${CONFIG_ITEMS[@]}"; do
    src="$REPO_DIR/.config/$item"
    [[ -e "$src" ]] || continue
    backup_and_place "$src" "$HOME/.config/$item"
done

# Themes live at the repo root, not under .config/.
if [[ -d "$REPO_DIR/.themes" ]]; then
    mkdir -p "$HOME/.themes"
    for theme in "$REPO_DIR/.themes"/*; do
        [[ -e "$theme" ]] || continue
        backup_and_place "$theme" "$HOME/.themes/$(basename "$theme")"
    done
fi

# ---------------------------------------------------------------------------
# 6. Repair the repo's absolute symlinks
# ---------------------------------------------------------------------------
# Upstream ships waybar/config and waybar/style.css as symlinks to
# /home/hypr/..., which is a broken link on any other machine. Point them at
# the real files inside your own ~/.config instead.
repair_symlink() {
    local link="$1" target="$2"
    [[ -L "$link" ]] || return 0
    local current; current="$(readlink "$link")"
    [[ "$current" == /* ]] || return 0          # relative link, fine
    [[ -e "$link" ]] && return 0                 # absolute but valid here
    [[ -e "$target" ]] || { warn "Cannot repair $link — $target is missing."; return 0; }
    info "Repairing broken symlink: ${link#"$HOME"/} -> $(basename "$target")"
    run ln -sfn "$target" "$link"
}

repair_symlink "$HOME/.config/waybar/config" \
    "$HOME/.config/waybar/configs/[TOP] wallust_new"
repair_symlink "$HOME/.config/waybar/style.css" \
    "$HOME/.config/waybar/style/[Dark] Purpl.css"

# rofi's wallpaper preview is a symlink to a file that ships with neither repo.
if [[ -L "$HOME/.config/rofi/.current_wallpaper" && ! -e "$HOME/.config/rofi/.current_wallpaper" ]]; then
    run rm -f "$HOME/.config/rofi/.current_wallpaper"
fi

# ---------------------------------------------------------------------------
# 7. swww -> awww compatibility
# ---------------------------------------------------------------------------
# Hyprlust was written against swww. Upstream swww was renamed to awww, and the
# Arch package is now `awww`, which brings three breaking changes:
#   1. the binary is `awww`, not `swww`
#   2. `swww img -o OUT` became `awww img --output OUT`
#   3. the cache moved from ~/.cache/swww/OUT to ~/.cache/awww/<version>/OUT
# Hyprland's `exec` does not consult fish's PATH, so a wrapper script dropped
# in ~/.local/bin is not reliable. Patch the affected scripts in place.
# Every edit below is idempotent, so re-running the installer is safe.
if command -v awww >/dev/null && ! command -v swww >/dev/null; then
    info "Adapting Hyprlust scripts from swww to awww..."

    if (( DRY_RUN )); then
        printf '  + rewrite swww -> awww in ~/.config/hypr/{scripts,UserScripts}\n'
        printf "  + teach WallustSwww.sh about awww's versioned cache\n"
    else
        _patched=0
        while IFS= read -r -d '' f; do
            # Order matters: handle the daemon name and the short -o flag
            # before the catch-all rename.
            if grep -qE '\bswww\b|swww-daemon' "$f"; then
                sed -i \
                    -e 's/swww-daemon/awww-daemon/g' \
                    -e 's/swww img -o /awww img --output /g' \
                    -e 's/\bswww\b/awww/g' \
                    "$f"
                _patched=$((_patched + 1))
            fi
        done < <(grep -rlZ --binary-files=without-match 'swww' \
                    "$HOME/.config/hypr/scripts" \
                    "$HOME/.config/hypr/UserScripts" \
                    "$HOME/.config/hypr/initial-boot.sh" 2>/dev/null || true)
        (( _patched > 0 )) && ok "Patched $_patched script(s) to use awww."

        # WallustSwww.sh hardcodes the old cache path. awww stores images under
        # ~/.cache/awww/<version>/<output>, so teach the script to descend into
        # the newest version directory. Runs after the rename above, which is
        # why it matches the already-rewritten awww path.
        WALLUST_SH="$HOME/.config/hypr/scripts/WallustSwww.sh"
        if [[ -f "$WALLUST_SH" ]]; then
            if ! grep -q 'hyprlust-install' "$WALLUST_SH"; then
                RESOLVER='cache_dir="$HOME/.cache/awww/"; _n="$(find "$HOME/.cache/awww" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -n 1)"; [ -n "$_n" ] && cache_dir="$_n/" # hyprlust-install'
                # sed treats & \ and the delimiter specially inside a
                # replacement, so escape all three.
                _repl=${RESOLVER//\\/\\\\}
                _repl=${_repl//&/\\&}
                _repl=${_repl//@/\\@}
                sed -i "s@^cache_dir=\"\$HOME/\.cache/awww/\"\$@${_repl}@" "$WALLUST_SH"
                ok "Taught WallustSwww.sh to find awww's cache directory."
            fi
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 8. Wallpapers & directories
# ---------------------------------------------------------------------------
# Hyprlust hardcodes ~/Pictures/wallpapers (lowercase w).
mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Music"

WALL_SRC=""
for d in "$REPO_DIR/wallpapers" "$REPO_DIR/Wallpapers" "$REPO_DIR/Pictures/wallpapers"; do
    [[ -d "$d" ]] && { WALL_SRC="$d"; break; }
done

if [[ -n "$WALL_SRC" ]]; then
    info "Copying wallpapers from $WALL_SRC..."
    run cp -an "$WALL_SRC/." "$HOME/Pictures/wallpapers/"
    ok "Wallpapers copied to ~/Pictures/wallpapers"
else
    # Upstream keeps wallpapers in a separate repo; don't pull 450 MB silently.
    warn "No wallpapers bundled in the repo."
    warn "Grab them yourself if you want the wallpaper picker to work:"
    warn "  git clone --depth=1 https://github.com/NischalDawadi/Wallpapers \\"
    warn "      ~/Pictures/wallpapers"
fi

# ---------------------------------------------------------------------------
# 9. Fix hardcoded /home/hypr paths
# ---------------------------------------------------------------------------
# Several upstream configs hardcode the original author's home directory.
# Rewrite them to $HOME so keybinds and caches resolve on your machine.
info "Rewriting hardcoded /home/hypr paths to $HOME..."
if (( DRY_RUN )); then
    printf '  + grep -rl /home/hypr ~/.config and rewrite\n'
else
    while IFS= read -r -d '' f; do
        sed -i "s|/home/hypr|$HOME|g" "$f"
    done < <(grep -rlZ --binary-files=without-match '/home/hypr' "$HOME/.config" 2>/dev/null || true)
fi

# ---------------------------------------------------------------------------
# 10. Permissions
# ---------------------------------------------------------------------------
info "Making Hyprlust scripts executable..."
if (( DRY_RUN )); then
    printf '  + chmod +x ~/.config/hypr/{scripts,UserScripts}/*\n'
else
    find "$HOME/.config/hypr/scripts" "$HOME/.config/hypr/UserScripts" \
        -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
    chmod +x "$HOME/.config/hypr/initial-boot.sh" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 11. Services
# ---------------------------------------------------------------------------
info "Enabling NetworkManager and Bluetooth..."
run sudo systemctl enable --now NetworkManager.service
run sudo systemctl enable --now bluetooth.service

# ---------------------------------------------------------------------------
# 12. NVIDIA hint
# ---------------------------------------------------------------------------
if (( GPU_NVIDIA )); then
    warn "NVIDIA GPU detected."
    warn "Hyprlust's ENVariables.conf already carries the standard NVIDIA"
    warn "variables but leaves them commented out. Before your first login,"
    warn "install the driver and enable those lines:"
    warn "  sudo pacman -S --needed nvidia-dkms nvidia-utils libva-nvidia-driver"
    warn "  \$EDITOR ~/.config/hypr/UserConfigs/ENVariables.conf"
fi

# ---------------------------------------------------------------------------
# 13. Default shell -> fish
# ---------------------------------------------------------------------------
FISH_BIN="$(command -v fish || true)"
if [[ -n "$FISH_BIN" ]]; then
    # /bin is usually a symlink to /usr/bin, so compare resolved paths —
    # otherwise "/bin/fish" != "/usr/bin/fish" triggers a pointless chsh.
    FISH_REAL="$(readlink -f "$FISH_BIN")"
    SHELL_REAL="$(readlink -f "${SHELL:-}" 2>/dev/null || printf '%s' "${SHELL:-}")"

    # Make sure fish is in /etc/shells or chsh refuses.
    grep -qxF "$FISH_BIN" /etc/shells 2>/dev/null \
        || run sudo sh -c "echo '$FISH_BIN' >> /etc/shells"

    if [[ "$SHELL_REAL" != "$FISH_REAL" ]]; then
        info "Current shell is ${SHELL:-unknown}."
        # Read from /dev/tty so the prompt still works when piped through curl.
        # Fall back to a non-interactive default if there is no terminal.
        reply=""
        if ( exec </dev/tty ) 2>/dev/null; then
            read -rp "Set fish as your default shell? [y/N] " reply </dev/tty || reply=""
        else
            info "No terminal available — defaulting to yes."
            reply="y"
        fi
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            run chsh -s "$FISH_BIN"
            ok "Default shell set to $FISH_BIN (takes effect next login)."
        else
            info "Keeping ${SHELL:-your current shell}. Switch later with: chsh -s $FISH_BIN"
        fi
    else
        ok "Fish is already your default shell."
    fi

    # Fisher plugins: fish's equivalent of the zsh plugin dirs upstream ships.
    if command -v fisher >/dev/null; then
        info "Installing fish plugins (fisher)..."
        run fish -c 'fisher install jorgebucaran/fisher PatrickF1/fzf.fish jorgebucaran/nvm.fish' \
            || warn "Some fish plugins failed to install — run 'fisher update' later."
    fi
else
    warn "fish was not found after the package install — skipping shell switch."
fi

# ---------------------------------------------------------------------------
# 14. Summary
# ---------------------------------------------------------------------------
# Only keep a backup dir if something was actually put in it.
if [[ -d "$BACKUP_DIR" ]]; then
    if [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        rmdir "$BACKUP_DIR" 2>/dev/null || true
    else
        ok "Previous configs backed up to $BACKUP_DIR"
    fi
fi

echo
ok "Hyprlust (fish edition) installation complete."
cat <<EOF

  ${C_WARN}Before you log in:${C_OFF}
    1. Review ~/.config/hypr/UserConfigs/Monitors.conf and set your real
       monitor name and resolution. Left as-is, Hyprland guesses.
    2. Set a wallpaper so the first login is not black:
         awww-daemon & awww img ~/Pictures/wallpapers/<file>

  ${C_WARN}Next steps:${C_OFF}
    3. Log out, then pick "Hyprland" in your display manager.
       From a TTY: Hyprland
    4. Apply GTK/Qt themes with nwg-look and qt6ct.
    5. Super+Shift+H lists the actual keybinds.

  ${C_WARN}Not installed on purpose:${C_OFF}
    - spicetify, Seanime, Upscayl and their caches (100+ MB of app state)
    - ags (Aylur's GTK Shell): the upstream exec-once line for it is a
      leftover; the waybar bar is the active one. Remove that line if it
      spams your log.

EOF
