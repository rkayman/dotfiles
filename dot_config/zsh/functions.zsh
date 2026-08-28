# Create a directory and enter it.
mkcd() {
    [[ -z "$1" ]] && return 1
    mkdir -p "$1" && cd "$1"
}

# Open a path in Finder.
finder() {
    open "${1:-.}"
}

# Copy current directory to clipboard.
cpwd() {
    pwd | tr -d '\n' | pbcopy
}

# Open current directory in editor.
e() {
    ${EDITOR:-vi} "${1:-.}"
}

# Find and kill a process interactively.
fkill() {
    local pid

    pid="$(
        ps -ef |
        sed 1d |
        fzf --multi \
            --header='Select process(es) to kill' |
        awk '{print $2}'
    )" || return

    [[ -n "$pid" ]] && echo "$pid" | xargs kill -9
}

# Search file content using ripgrep + fzf and open result in editor.
frg() {
    local result file line

    result="$(
        rg \
            --column \
            --line-number \
            --no-heading \
            --color=always \
            --smart-case \
            "${1:-}" |
        fzf \
            --ansi \
            --delimiter=: \
            --preview='bat --color=always --highlight-line {2} {1}' \
            --preview-window='right,60%,border-left,+{2}+3/3,~3'
    )" || return

    file="${result%%:*}"
    line="$(cut -d: -f2 <<< "$result")"

    [[ -n "$file" ]] && ${EDITOR:-vi} "$file:$line"
}

# Choose a Git branch and switch to it.
gb() {
    local branch

    branch="$(
        git branch --all --color=always |
        sed 's/^[* ]*//' |
        grep -v 'HEAD' |
        fzf --ansi \
            --preview='git log --oneline --graph --decorate --color=always {} --'
    )" || return

    branch="${branch#remotes/origin/}"

    [[ -n "$branch" ]] && git switch "$branch"
}

# Choose a Git commit and show it.
gshow() {
    local commit

    commit="$(
        git log \
            --color=always \
            --format='%C(auto)%h%d %s %C(black)%C(bold)%cr' |
        fzf \
            --ansi \
            --no-sort \
            --reverse \
            --preview='git show --color=always {1}' \
            --preview-window='right,60%'
    )" || return

    [[ -n "$commit" ]] && git show "${commit%% *}"
}

# Choose a JJ revision and display it.
jshow() {
    local change_id

    change_id="$(
        jj log \
            --no-graph \
            -T 'change_id.shortest() ++ "  " ++ description.first_line() ++ "\n"' |
        fzf --preview='jj show {1}'
    )" || return

    [[ -n "$change_id" ]] && jj show "${change_id%% *}"
}

# Choose a JJ revision and edit it.
jedit() {
    local change_id

    change_id="$(
        jj log \
            --no-graph \
            -T 'change_id.shortest() ++ "  " ++ description.first_line() ++ "\n"' |
        fzf --preview='jj show {1}'
    )" || return

    [[ -n "$change_id" ]] && jj edit "${change_id%% *}"
}

vman() { 
    man "$1" | col -bx | open -fa /Applications/Visual\ Studio\ Code.app 
}

pman() {
    pman_args=("$@");
    gman -Tpdf "${pman_args[@]}" > /dev/null && gman -Tpdf "${pman_args[@]}" | open -fa Preview
}

function det() { 
    ls -al $(where "$1") 
}

function yg() {
    if [[ -n "$2" ]]
    then
        yt-dlp --format "$1" "$2"
    else
        yt-dlp -F "$1"
    fi
}
