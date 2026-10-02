export FZF_DEFAULT_OPTS='--ansi'  # --ansi 选项使 fzf 可以带有 fd 的彩色输出
export FZF_DEFAULT_COMMAND='fd --type f --color=auto --hidden --follow --exclude .git'  # 遵循符号链接: --follow;  并包含隐藏文件: --hidden (但不包括.git文件夹) :

# Tokyo Night color scheme for fzf
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7 \
  --color=fg+:#c0caf5,bg+:#2f3549,hl+:#7dcfff \
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff \
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"
