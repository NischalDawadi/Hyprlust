# ========================
# >> Environment Setup
# ========================

export EDITOR="nvim"
export MANPAGER="$EDITOR +Man!"

# Unified PATH setup
export PATH="$HOME/bin:/usr/local/bin:/home/hypr/.local/bin:/home/hypr/.cargo/bin:$HOME/.bun/bin:/home/hypr/.spicetify:$PATH"

# Cargo env
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# ========================
# >> Plugins
# ========================
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-completions/zsh-completions.plugin.zsh
# ========================
# >> Tools Init
# ========================
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# tdl completion

# ========================
# >> Appearance / Theme
# ========================
# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
HISTDUPE=erase

# zsh options
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Freetype font rendering tweaks
export FREETYPE_PROPERTIES="truetype:interpreter-version=35 autofitter:no-stem-darkening=0 cff:no-stem-darkining=0"

zstyle ':completion:*' file-sort date
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:paths' path-completion yes
zstyle ':completion:*:processes' command 'ps -afu $USER'
zstyle ':autocomplete:*' min-input 1
zstyle ':autocomplete:*' insert-unambiguous yes

# ========================
# >> Aliases
# ========================
alias ls='exa --icons --color=always --group-directories-first'
alias v="nvim"
alias ll='exa -alF --icons --color=always --group-directories-first'
alias la='exa -a --icons --color=always --group-directories-first'
alias l='exa -F --icons --color=always --group-directories-first'
alias lf='yazi'
alias pdf='soffice --headless --convert-to pdf'

# ========================
# >> Other Exports
# ========================
export LIBVIRT_DEFAULT_URI="qemu:///system"

# ========================
# >> Optional / Commented Tools
# ========================
# ========================
export FZF_DEFAULT_OPTS='
--color=spinner:2,hl:6
--color=fg:7,header:3,info:4,pointer:4
--color=marker:2,fg+:7,prompt:6,hl+:6
'
