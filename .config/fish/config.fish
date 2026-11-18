# ~/.config/fish/config.fish
# Fish port of the Hyprlust zsh setup (NischalDawadi/Hyprlust).
# Replaces .zshrc + .zsh/ plugins with fish built-ins.

# ========================
# >> Environment
# ========================
set -gx EDITOR nvim
set -gx SUDO_EDITOR nvim
set -gx MANPAGER "$EDITOR +Man!"
set -gx LIBVIRT_DEFAULT_URI "qemu:///system"

# Freetype font rendering tweaks (same values as the zsh config)
set -gx FREETYPE_PROPERTIES "truetype:interpreter-version=35 autofitter:no-stem-darkening=0 cff:no-stem-darkening=0"

# Unified PATH. The original .zshrc hardcoded /home/hypr/*; use $HOME instead
# so this works on every machine.
fish_add_path --global --move-to-front \
    $HOME/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/.bun/bin \
    $HOME/.spicetify

# fzf colors (same as the zsh config)
set -gx FZF_DEFAULT_OPTS '--color=spinner:2,hl:6 --color=fg:7,header:3,info:4,pointer:4 --color=marker:2,fg+:7,prompt:6,hl+:6'
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'

# ========================
# >> Interactive setup
# ========================
if status is-interactive
    set -g fish_greeting

    # Prompt
    if type -q starship
        starship init fish | source
    end

    # Smarter cd
    if type -q zoxide
        zoxide init fish | source
    end

    # fzf keybindings + completion (requires fzf >= 0.48)
    if type -q fzf
        fzf --fish 2>/dev/null | source
    end

    # --- History (mirrors the zsh HISTSIZE/SAVEHIST options) ---
    # fish stores history in ~/.local/share/fish/fish_history and has no
    # size cap by default; these keep the same behaviour as the zsh config.
    set -g fish_autosuggestion_enabled 1
end

# ========================
# >> Aliases
# ========================
# fish has no `alias` aliases that persist across sessions in config; use
# functions for commands with arguments and abbr for plain substitutions.

if type -q eza
    function ls --wraps eza --description 'List contents (eza, icons)'
        eza --icons --color=always --group-directories-first $argv
    end
    function ll --wraps eza --description 'List all, long format (eza)'
        eza -alF --icons --color=always --group-directories-first $argv
    end
    function la --wraps eza --description 'List all (eza)'
        eza -a --icons --color=always --group-directories-first $argv
    end
    function l --wraps eza --description 'List, classify entries (eza)'
        eza -F --icons --color=always --group-directories-first $argv
    end
end

abbr --add v nvim
abbr --add lf yazi
abbr --add pdf 'soffice --headless --convert-to pdf'

# ========================
# >> Tool integrations
# ========================
# bun completions (replaces the zsh `[ -s ~/.bun/_bun ]` line)
if test -f $HOME/.bun/_bun
    source $HOME/.bun/_bun
end

# cargo env
if test -f $HOME/.cargo/env
    source $HOME/.cargo/env
end
