# `,` + <Tab> -> zoxide 目录选择 (fzf), 选中后替换掉 `,`
#   cp ,<Tab>  -> 弹出 zoxide 列表, 选完替换 `,`, 继续输入; 下个目录再 `,<Tab>`
# 光标前最后一个词恰好是 `,` 才触发, 否则回退到原来的 Tab 行为 (fzf-tab / kitty 补全)

_zoxide_comma_try() {
  [[ $LBUFFER == (|*[[:space:]])',' ]] || return 1
  local dir
  zle -I
  dir=$(zoxide query -l 2>/dev/null | fzf --height=40% --reverse --scheme=path \
          --tiebreak=index --prompt='zoxide> ' \
          --preview 'eza -1 --color=always --icons=auto {}')
  if [[ -n $dir ]]; then
    LBUFFER=${LBUFFER%,}${(q)dir}
  fi
  zle reset-prompt
  return 0
}

typeset -gA _zoxide_comma_fallback
_zoxide_comma_widget() {
  _zoxide_comma_try || zle "${_zoxide_comma_fallback[$WIDGET]}"
}

# $1: 新 widget 名, $2: 未命中 `,` 时回退的 widget
_zoxide_comma_wrap() {
  _zoxide_comma_fallback[$1]=$2
  zle -N "$1" _zoxide_comma_widget
}

# 必须在 fzf-tab (wait'1') 接管 ^I 之后再包装, 以便拿到最终的回退 widget
_zoxide_comma_install() {
  local map fb
  fb=$(bindkey -M main '^I')
  fb=${fb##* }
  [[ $fb == undefined-key || $fb == _zoxide_comma_tab ]] && fb=expand-or-complete
  _zoxide_comma_wrap _zoxide_comma_tab $fb
  for map in main viins emacs; do
    bindkey -M $map '^I' _zoxide_comma_tab
  done

  # kitty: Tab 先走 kitty-tab-or-complete, 其内部回退再套一层
  if [[ -n $_kitty_tab_fallback && $_kitty_tab_fallback != _zoxide_comma_kitty ]]; then
    _zoxide_comma_wrap _zoxide_comma_kitty $_kitty_tab_fallback
    _kitty_tab_fallback=_zoxide_comma_kitty
  fi
}

zinit ice wait'2' lucid atload'_zoxide_comma_install'
zinit light zdharma-continuum/null
