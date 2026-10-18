# zmx — session persistence (abduco/dtach 家族)
# 关 kitty == detach, daemon 留住 pty; 重开后 zpick 真正 reattach (恢复光标 + scrollback)
(( $+commands[zmx] )) || return 0

# session 名称前缀分组. 例:
#   alias zphd='ZMX_SESSION_PREFIX=phd. '
#   alias ztu='ZMX_SESSION_PREFIX=tushare. '
# 之后 `zphd zpick` 只看 phd.* 的 session, ctrl-n 自动加前缀
typeset -gx ZMX_SESSION_PREFIX=${ZMX_SESSION_PREFIX:-}

# 模仿 _tmux 的 __tmux-sessions-separately + fzf-tab:
# 1. `/usr/share/zsh/site-functions/_zmx` 缺少首行 `#compdef zmx` 导致 compinit 未自动注册
# 2. 按 clients 数量拆分为 detached session / attached session 两个 tag 分组 (支持 fzf-tab `<` `>` 切组),
#    并附带 pid / clients / start_dir 描述与终端 scrollback 预览
_zmx_sessions() {
  local ret=1
  local pfx=${ZMX_SESSION_PREFIX:-}
  local cur=""
  [[ ${words[2]} == (attach|a) ]] && cur=${ZMX_SESSION:-}
  local -a detached_sessions attached_sessions
  local line field k v name pid clients start_dir desc

  for line in ${(f)"$(command zmx list 2>/dev/null)"}; do
    name="" pid="" clients="" start_dir=""
    for field in ${(ps:\t:)line}; do
      field=${field## #}
      [[ $field == *=* ]] || continue
      k=${field%%=*}
      v=${field#*=}
      case $k in
        name)      name=$v ;;
        pid)       pid=$v ;;
        clients)   clients=$v ;;
        start_dir) start_dir=$v ;;
      esac
    done
    [[ -z $name || $name == "$cur" ]] && continue
    [[ -n $pfx && $name != ${pfx}* ]] && continue

    desc="pid:${pid:-?}  cl:${clients:-0}${start_dir:+  ${start_dir/#$HOME/~}}"
    if (( ${clients:-0} > 0 )); then
      attached_sessions+=( "${name//:/\\:}:${desc} (attached)" )
    else
      detached_sessions+=( "${name//:/\\:}:${desc}" )
    fi
  done

  _tags detached-sessions attached-sessions
  _requested detached-sessions && _describe -t detached-sessions 'detached session' detached_sessions "$@" && ret=0
  _requested attached-sessions && _describe -t attached-sessions 'attached session' attached_sessions "$@" && ret=0
  return ret
}

_zmx() {
  local curcontext="$curcontext" state line ret=1
  typeset -A opt_args

  _arguments -C \
    '1: :->commands' \
    '2: :->args' \
    '*: :->trailing' && ret=0

  case $state in
    commands)
      local -a commands=(
        'attach:Attach to session, creating if needed'
        'run:Send command without attaching'
        'write:Write stdin to file_path through the session'
        'detach:Detach all clients from current session'
        'list:List active sessions'
        'kill:Kill session and all attached clients'
        'history:Output session scrollback'
        'wait:Wait for session tasks to complete'
        'tail:Follow session output'
        'completions:Shell completion scripts'
        'version:Show version'
        'help:Show help message'
      )
      local -a aliases=(
        'a:Attach to session, creating if needed'
        'r:Send command without attaching'
        'wr:Write stdin to file_path through the session'
        'd:Detach all clients from current session'
        'l:List active sessions'
        'k:Kill session and all attached clients'
        'hi:Output session scrollback'
        'w:Wait for session tasks to complete'
        't:Follow session output'
        'c:Shell completion scripts'
        'v:Show version'
        'h:Show help message'
      )
      _describe -t commands 'zmx command' commands -- aliases && ret=0
      ;;
    args)
      case $words[2] in
        attach|a|kill|k|run|r|write|wr|history|hi|wait|w|tail|t)
          curcontext="${curcontext%:*}-${words[2]}:"
          _zmx_sessions && ret=0
          ;;
        completions|c)
          _values 'shell' 'bash' 'zsh' 'fish' && ret=0
          ;;
        list|l)
          _values 'options' '--short' && ret=0
          ;;
      esac
      ;;
    trailing)
      case $words[2] in
        attach|a|run|r)
          _cmdambivalent && ret=0
          ;;
        kill|k|wait|w|tail|t)
          curcontext="${curcontext%:*}-${words[2]}:"
          _zmx_sessions && ret=0
          ;;
        write|wr)
          if (( CURRENT == 4 )); then
            _files && ret=0
          fi
          ;;
        history|hi)
          _values 'options' '--vt' '--html' && ret=0
          ;;
      esac
      ;;
  esac
  return ret
}

if (( $+functions[compdef] )); then
  compdef _zmx zmx
elif (( $+functions[zicompdef] )); then
  zicompdef _zmx zmx
fi

# fzf-tab 预览与快捷键:
# - 补全 session 时右侧实时预览该 session 的终端画面 (scrollback)
# - 在 `zmx attach <Tab>` 弹出的 fzf-tab 菜单中:
#   - `ctrl-x`: 直接 kill 当前高亮的 session
zstyle ':fzf-tab:complete:zmx-(attach|a|kill|k|run|r|write|wr|history|hi|wait|w|tail|t):*' \
  fzf-preview 'zmx history --vt $word 2>/dev/null | tail -n 200'
zstyle ':fzf-tab:complete:zmx-(attach|a|kill|k|run|r|write|wr|history|hi|wait|w|tail|t):*' \
  fzf-flags --preview-window=right:60%:follow \
            --header=$'< >:switch group  C-x:kill session' \
            --bind='ctrl-x:execute-silent({_FTB_INIT_}command zmx kill -- "$word" >/dev/null 2>&1)'

# attach / switch 包装:
# - 若已在 zmx session 内 (`$ZMX_SESSION` 非空):
#   不直接嵌套 attach, 而是把目标记入交换文件并触发 `zmx detach`,
#   由外层主机的 `_zmx_attach` 捕获后无缝切换到目标 session (类似 `tmux switch-client`)
# - 在 kitty 中同步更新 tab 标题, detach 后恢复自动标题
_zmx_switch_file() {
  print -r -- "${XDG_RUNTIME_DIR:-/tmp}/zmx-switch-${UID}"
}

_zmx_attach() {
  local name=$1
  shift
  [[ -z $name ]] && return 1

  # 已经在某个 zmx 会话内: 执行跳转而非套娃
  if [[ -n $ZMX_SESSION ]]; then
    if [[ $name == "$ZMX_SESSION" ]]; then
      return 0
    fi
    local sw_file=$(_zmx_switch_file)
    print -r -- "$name" >| "$sw_file"
    if (( $# > 0 )); then
      command zmx run "$name" "$@" 2>/dev/null || true
    fi
    command zmx detach
    return
  fi

  local sw_file=$(_zmx_switch_file)
  command rm -f "$sw_file" 2>/dev/null
  local -a init_args=("$@")
  local ret=0

  while [[ -n $name ]]; do
    if [[ $TERM == xterm-kitty ]] && (( $+commands[kitten] )); then
      kitten @ set-tab-title "zmx:${name}" 2>/dev/null
      {
        command zmx attach "$name" "${init_args[@]}" || ret=$?
      } always {
        kitten @ set-tab-title "" 2>/dev/null
      }
    else
      command zmx attach "$name" "${init_args[@]}" || ret=$?
    fi
    init_args=()

    if [[ -s $sw_file ]]; then
      name=$(<"$sw_file")
      command rm -f "$sw_file" 2>/dev/null
    else
      name=""
    fi
  done
  return $ret
}

# 解析 `zmx list` 输出 (tab 分隔的 key=val), 按 prefix 过滤并按状态着色
# 传 `-x` 时额外过滤掉当前所在的 `$ZMX_SESSION`
_zmx_rows() {
  local exclude_cur=""
  [[ $1 == "-x" ]] && exclude_cur=${ZMX_SESSION:-}
  local pfx=${ZMX_SESSION_PREFIX:-}
  command zmx list 2>/dev/null | awk -F'\t' -v pfx="$pfx" -v home="$HOME" -v cur="$exclude_cur" '
    {
      delete a
      for (i=1; i<=NF; i++) {
        gsub(/^ +/, "", $i)
        n = index($i, "=")
        if (n == 0) continue
        a[substr($i, 1, n-1)] = substr($i, n+1)
      }
      if (a["name"] == "" || a["status"] == "unreachable") next
      if (cur != "" && a["name"] == cur) next
      if (pfx != "" && index(a["name"], pfx) != 1) next

      dir = a["start_dir"]
      if (home != "" && index(dir, home) == 1) {
        dir = "~" substr(dir, length(home) + 1)
      }

      if (a["ended"] != "") {
        code = (a["exit_code"] != "" ? a["exit_code"] : "0")
        c = (code == "0" ? "\033[90m" : "\033[31m")
        st = sprintf("exit:%-3s", code)
      } else if (a["clients"] + 0 > 0) {
        c = "\033[32m"
        st = sprintf("cl:%-5s", a["clients"])
      } else {
        c = "\033[36m"
        st = sprintf("cl:%-5s", a["clients"] != "" ? a["clients"] : "0")
      }
      printf "%s%-28s\033[0m  pid:%-7s  %s  %s\n", c, a["name"], a["pid"], st, dir
    }'
}

# 结合 zoxide 选择历史目录并以目录名 attach (类似 sesh / tmux-sessionizer)
_zmx_zoxide_pick() {
  local pfx=${ZMX_SESSION_PREFIX:-}
  local dir
  dir=$(zoxide query -l 2>/dev/null | fzf \
    --prompt="zmx dir${pfx:+ ($pfx)}> " \
    --header="select directory to cd & zmx attach" \
    --preview='eza -1 --color=always --icons {} 2>/dev/null || ls -la --color=always {}') || return
  [[ -z $dir ]] && return
  # 若在外部 shell, 直接 cd 过去使得新建 session 的 start_dir 为该目录;
  # 若已在 session 内跳转, 不改变原 session 的工作目录, 仅在新 session 不存在时让其在对应目录启动
  if [[ -z $ZMX_SESSION ]]; then
    builtin cd -- "$dir" || return
  else
    ( builtin cd -- "$dir" && command zmx run "${pfx}${dir:t}" true >/dev/null 2>&1 ) &!
    sleep 0.05
  fi
  _zmx_attach "${pfx}${dir:t}"
}

zpick() {
  local pfx=${ZMX_SESSION_PREFIX:-}
  local rows out query key sel name cmd reload_cmd prompt_str
  local -a lines
  rows=$(_zmx_rows -x)
  reload_cmd="zsh -c 'source ~/.config/zsh/zshrc.d/55-zmx.zsh >/dev/null 2>&1; _zmx_rows -x'"
  if [[ -n $ZMX_SESSION ]]; then
    prompt_str="zmx switch (${ZMX_SESSION}${pfx:+ | $pfx})> "
  else
    prompt_str="zmx${pfx:+ ($pfx)}> "
  fi
  out=$(print -r -- "$rows" | fzf \
    --ansi \
    --print-query \
    --expect=ctrl-o,ctrl-f,ctrl-r,ctrl-y \
    --bind="ctrl-x:execute-silent(command zmx kill {1} >/dev/null 2>&1; sleep 0.1)+reload($reload_cmd)" \
    --prompt="$prompt_str" \
    --header=$'enter:attach/switch/new(query)  C-f:zoxide dir  C-x:kill  C-r:run  C-y:history' \
    --preview='[[ -n {1} ]] && command zmx history --vt {1} 2>/dev/null | tail -200' \
    --preview-window=right:60%:follow) || return
  lines=("${(@f)out}")
  query=${lines[1]}
  key=${lines[2]}
  sel=${lines[3]}
  name=${${(z)sel}[1]}
  case $key in
    ctrl-o)
      [[ -z $query ]] && { print -u2 "zpick: empty query, no name to create"; return 1 }
      _zmx_attach "${pfx}${query}"
      ;;
    ctrl-f)
      _zmx_zoxide_pick
      ;;
    ctrl-r)
      [[ -z $name ]] && return
      print -n "cmd> "
      read -r cmd || return
      [[ -z $cmd ]] && return
      command zmx run "$name" zsh -c "$cmd"
      ;;
    ctrl-y)
      [[ -z $name ]] && return
      command zmx history "$name" | less -R
      ;;
    "")
      if [[ -n $name ]]; then
        _zmx_attach "$name"
      elif [[ -n $query ]]; then
        _zmx_attach "${pfx}${query}"
      fi
      ;;
  esac
}

# 快捷交互:
# - `zmx` / `zmx attach|a` (无参) -> 打开 zpick 面板 (若已在 session 内则过滤当前 session 并支持跳转)
# - `zmx kill|k` (无参)           -> fzf 多选批量 kill
# - `zmx history|hi` (无参)       -> fzf 选择并用 less -R 查看回滚历史
# - `zmx tail|t` (无参)           -> fzf 多选并实时 tail
zmx() {
  if (( $# == 0 )); then
    zpick
    return
  fi

  case $1 in
    attach|a)
      if (( $# == 1 )); then
        zpick
      else
        shift
        _zmx_attach "$@"
      fi
      ;;
    kill|k)
      if (( $# == 1 )); then
        local rows sel
        rows=$(_zmx_rows)
        [[ -z $rows ]] && { print -u2 "zmx kill: no active sessions"; return 1 }
        local -a targets
        sel=$(print -r -- "$rows" | fzf -m \
          --ansi \
          --prompt="zmx kill> " \
          --header="tab:multi-select  enter:kill selected" \
          --preview='[[ -n {1} ]] && command zmx history --vt {1} 2>/dev/null | tail -200' \
          --preview-window=right:60%:follow) || return
        targets=( ${${(f)sel}/(#b)([^[:space:]]##)*/$match[1]} )
        (( $#targets )) && command zmx kill "${targets[@]}"
      else
        command zmx "$@"
      fi
      ;;
    history|hi)
      if (( $# == 1 )); then
        local rows sel name
        rows=$(_zmx_rows)
        [[ -z $rows ]] && { print -u2 "zmx history: no active sessions"; return 1 }
        sel=$(print -r -- "$rows" | fzf \
          --ansi \
          --prompt="zmx history> " \
          --preview='[[ -n {1} ]] && command zmx history --vt {1} 2>/dev/null | tail -200' \
          --preview-window=right:60%:follow) || return
        name=${${(z)sel}[1]}
        [[ -n $name ]] && command zmx history "$name" | less -R
      else
        command zmx "$@"
      fi
      ;;
    tail|t)
      if (( $# == 1 )); then
        local rows sel
        rows=$(_zmx_rows)
        [[ -z $rows ]] && { print -u2 "zmx tail: no active sessions"; return 1 }
        local -a targets
        sel=$(print -r -- "$rows" | fzf -m \
          --ansi \
          --prompt="zmx tail> " \
          --header="tab:multi-select  enter:tail selected" \
          --preview='[[ -n {1} ]] && command zmx history --vt {1} 2>/dev/null | tail -200' \
          --preview-window=right:60%:follow) || return
        targets=( ${${(f)sel}/(#b)([^[:space:]]##)*/$match[1]} )
        (( $#targets )) && command zmx tail "${targets[@]}"
      else
        command zmx "$@"
      fi
      ;;
    *)
      command zmx "$@"
      ;;
  esac
}

# session 内提示符标记 (zmx attach 时设置 ZMX_SESSION 环境变量)
if [[ -n $ZMX_SESSION ]]; then
  export PS1="[$ZMX_SESSION] ${PS1}"
fi
function prompt_my_zmx_session() {
  if [[ -n $ZMX_SESSION ]]; then
    p10k segment -b '%k' -f '%f' -t "[$ZMX_SESSION]"
  fi
}
typeset -ga POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS+=my_zmx_session
