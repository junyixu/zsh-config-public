if [[ "$TERM" == 'xterm-kitty' ]]; then
# 不要在 zsh 里 push kitty keyboard protocol (`\e[>1u`):
# disambiguate flag 会把 Ctrl+letter 重编码成 CSI u (Ctrl+c -> \e[99;5u 等),
# zsh 没全套绑定, 会导致 Ctrl+c / Ctrl+d 等失效.
#
# 至于区分 <C-i> / <Tab>:
# nvim 自动协商的 protocol 并不解决问题 —— vim/nvim key model 把 <C-i> 内部归一化为 <Tab>.
# 实际方案是在 kitty.conf 里 `map ctrl+i send_text all \x1b[25~` (vt220 F13),
# zsh / nvim 各自绑定它 (zsh 见 99-atuin.zsh 的 autosuggest-accept; nvim 绑 <F13>).
typeset -g _kitty_tab_fallback=''
if __kitty_binding=$(bindkey -M main '^I' 2>/dev/null); then
  _kitty_tab_fallback=${__kitty_binding##* }
  [[ $_kitty_tab_fallback == "undefined-key" ]] && _kitty_tab_fallback=''
fi
unset __kitty_binding

kitty-tab-or-complete() {
  if [[ -z $LBUFFER && -z $RBUFFER ]]; then
	LBUFFER+=$'\t'          # 没有输入时直接缩进
  elif [[ -n $_kitty_tab_fallback ]]; then
	zle "$_kitty_tab_fallback"  # 有输入时走原来的补全
  else
	LBUFFER+=$'\t'
  fi
}
zle -N kitty-tab-or-complete

[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"

kls() {
  kitty @ ls | jq -r '
    .[] |
    "╔═ OS Window \(.id) [\(.tabs | length) tabs]",
    (.tabs[] | "║  ├─ Tab \(.id): \(.title)")
  '
}

kjoin() {
  # 获取当前 OS Window ID
  local current_os_window=$(kitty @ ls | jq -r '
    .[] | select(.tabs[] | .windows[] | .is_self == true) | .id
  ')

  # 获取其他 OS Window 的 tabs
  local target_tab=$(kitty @ ls | jq -r --arg curr "$current_os_window" '
    .[] | select(.id != ($curr | tonumber)) | .tabs[] |
    "Tab \(.id) | \(.title)"
  ' | fzf --prompt="Select target tab to join: " --height=40% --reverse)

  # 提取 tab id
  if [[ -n "$target_tab" ]]; then
    local tab_id=$(echo "$target_tab" | awk -F'|' '{print $1}' | awk '{print $2}')
    kitty @ detach-tab --target-tab id:$tab_id
  fi
}

# 函数名: kd (Kitten Download)
# 用途: 使用 kitten transfer 将远程文件下载到本地 ~/Downloads/kitty/ 目录
function kd() {
    if [[ -z "$1" ]]; then
        echo "Usage: kd <remote_file_path>"
        echo "Example: kd /etc/nginx/sites-enabled/jyxu.tech.conf"
        return 1
    fi

    local local_target_dir="~/Downloads/kitten_transfer/"

    # 使用 kitten transfer 触发下载。
    # 第一个参数是服务器上的文件路径 ($1)
    # 第二个参数是本地的绝对路径 (~/Downloads/kitty/，kitten 会自动处理 ~)
    kitten transfer "$@" "$local_target_dir"
}


for map in main viins emacs; do
  bindkey -M "$map" $'\e[9;2u' kitty-tab-or-complete   # Tab -> 条件缩进/补全
  [[ -n $_kitty_tab_fallback ]] && \
	bindkey -M "$map" $'\e[105;5u' "$_kitty_tab_fallback"  # C-i -> 直接补全
done
unset map

# kitty.conf 把 ctrl+i / ctrl+m 重映射为 \e[25~ / \eOM, 这里作为独立功能键绑定:
#   <C-i> -> autosuggest-accept (绑定挪到 99-atuin.zsh 的 atload, 待 widget 就位)
#   <C-m> -> 重跑上一条命令       (等价 nvim :<C-p><CR>)
kitty-run-last-command() {
  local last=$(atuin history last --format "{command}" 2>/dev/null)
  [[ -z $last ]] && return
  BUFFER=$last
  zle accept-line
}
zle -N kitty-run-last-command
bindkey -M viins $'\eOM' kitty-run-last-command
bindkey -M emacs $'\eOM' kitty-run-last-command
fi

# shift+enter 换行
bindkey '^[^M' self-insert-unmeta

[[ "$TERM" == alacritty ]] && unset LSCOLORS && unset LS_COLORS && export TERM="xterm-256color"
