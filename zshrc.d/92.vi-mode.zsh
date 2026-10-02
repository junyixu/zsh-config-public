zinit snippet OMZ::plugins/vi-mode/vi-mode.plugin.zsh
# Keep a small local patch on top of OMZ vi-mode.
# Only add familiar emacs-style bindings in vi insert mode.
bindkey -M viins '^b' backward-char
bindkey -M viins '^f' forward-char
bindkey -M viins '^k' kill-line
bindkey -M viins '^u' backward-kill-line
bindkey -M viins '^y' yank
bindkey -M viins '\eb' backward-word
bindkey -M viins '\ef' forward-word

# 可视模式 alt v 进入vim
bindkey -M vicmd 'e' edit-command-line
# 插入模式 ctrl F 进入vim
# bindkey '^F' edit-command-line
