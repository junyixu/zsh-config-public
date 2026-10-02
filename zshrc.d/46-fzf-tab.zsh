# fzf-tab 必须在 compinit 后, fsh 前; fsh 必须最后
zinit light-mode for \
    wait'2' lucid \
        Aloxaf/fzf-tab \
    wait'3' lucid \
        zdharma-continuum/fast-syntax-highlighting

# fzf-tab
# https://github.com/Aloxaf/fzf-tab/blob/master/README_CN.md
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
# vivid 输出缓存, 换主题手动 rm ~/.cache/ls_colors
[[ -f ~/.cache/ls_colors ]] || vivid generate tokyonight-night > ~/.cache/ls_colors
export LS_COLORS="$(<~/.cache/ls_colors)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=enter:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

