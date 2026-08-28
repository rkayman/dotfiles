command -v fzf >/dev/null 2>&1 || return

# Catppuccin Mocha
export FZF_DEFAULT_OPTS="
    --height=65%
    --layout=reverse
    --border=rounded
    --info=inline
    --prompt='  '
    --pointer='▶'
    --marker='✓'
    --color=bg+:#313244,bg:#1e1e2e
    --color=spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8
    --color=info:#cba6f7,pointer:#f5e0dc
    --color=marker:#b4befe,fg+:#cdd6f4
    --color=prompt:#cba6f7,hl+:#f38ba8
    --color=border:#6c7086
"

# Skip expensive / noisy trees.
export FZF_CTRL_T_OPTS="
    --walker-skip .git,node_modules,target,.jj
    --preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null'
    --preview-window 'right,60%,border-left'
"

export FZF_ALT_C_OPTS="
    --walker-skip .git,node_modules,target,.jj
    --preview 'eza --tree --level=2 --icons=auto --color=always {} 2>/dev/null'
"

export FZF_CTRL_R_OPTS="
    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
    --header 'CTRL-Y: copy command'
"

source <(fzf --zsh)
