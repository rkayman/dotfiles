command -v tv >/dev/null 2>&1 || return

alias tvf='tv files'
alias tvd='tv dirs'
alias tvt='tv text'
alias tvg='tv git-repos'
alias tve='tv env'

# Open file(s) selected by Television.
tvo() {
    local selection
    selection="$(tv files)" || return
    [[ -n "$selection" ]] && ${EDITOR:-vi} ${(f)selection}
}

# Choose a directory and enter it.
tvcd() {
    local directory
    directory="$(tv dirs)" || return
    [[ -n "$directory" ]] && cd "$directory"
}

# Search text and let Television provide the richer UI.
tvrg() {
    tv text
}

# Search Git repositories and cd into the selected repo.
tvgcd() {
    local repo
    repo="$(tv git-repos)" || return
    [[ -n "$repo" ]] && cd "$repo"
}

# Pipe processes into Television.
tvps() {
    ps aux | tv
}

# Interactively browse Git log.
tvlog() {
    git log --oneline --decorate --all | tv
}
