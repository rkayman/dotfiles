# ---------------------------------------------------------------------------
# eza
# ---------------------------------------------------------------------------

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons=auto --group-directories-first'
    alias l='eza --icons=auto --group-directories-first'
    alias ll='eza -lah --icons=auto --group-directories-first --git'
    alias la='eza -a --icons=auto --group-directories-first'
    alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
    alias ltt='eza --tree --level=3 --icons=auto --group-directories-first'
fi

# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------

alias c='clear'
alias mkdir='mkdir -p'
alias dir='ls -Flags'

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------

alias bud='brew update'
alias bog='brew outdated --greedy'
alias bug='brew upgrade --greedy'
alias bc='brew cleanup'
alias bcp='brew cleanup --prune=0'
alias bd='brew doctor'

# ---------------------------------------------------------------------------
# Aerospace & Starship
# ---------------------------------------------------------------------------

alias ss='starship'
alias as='aerospace'

function ff() {
    aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --graph --decorate --oneline --all'
alias gp='git pull'
alias gP='git push'

# ---------------------------------------------------------------------------
# Jujutsu
# ---------------------------------------------------------------------------

alias j='jj'
alias js='jj status'
alias jl='jj log'
alias jd='jj diff'
alias jn='jj new'
alias je='jj edit'
alias jdsc='jj describe'
