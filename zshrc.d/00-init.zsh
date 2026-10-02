[[ -s "/etc/grc.zsh" ]] && source /etc/grc.zsh

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
unalias zi 2>/dev/null

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode lucid for \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

### Begin Zinit's Config {{{
# 跳过 p10k 的 `who -m` SSH 探测 (本地 shell, 无 SSH env 变量时直接标记非 SSH)
# 实际 SSH 进来时 SSH_CONNECTION 等会被 sshd 设置, 此分支不触发, p10k 正常检测
if [[ -z $SSH_CLIENT && -z $SSH_TTY && -z $SSH_CONNECTION ]]; then
    typeset -gix P9K_SSH=0
    typeset -gx _P9K_SSH_TTY=$TTY
fi

# p10k 主题
zinit ice depth=1; zinit light romkatv/powerlevel10k

# 补全 (wait 顺序: fpath扩充 + zstyle → compinit重放 → OMZ插件 compdef)
zinit light-mode for \
    wait lucid blockf \
        zsh-users/zsh-completions \
    wait lucid atload'zicompinit -d $XDG_CACHE_HOME/zcompdump-$ZSH_VERSION; zicdreplay' \
        OMZ::lib/completion.zsh \
    wait'1' lucid \
        OMZ::plugins/extract/extract.plugin.zsh \
        OMZ::plugins/git/git.plugin.zsh


# 快速目录跳转
# eval "$(zoxide init zsh)" 
[[ -f ~/.cache/zoxide.zsh ]] || zoxide init zsh > ~/.cache/zoxide.zsh
source ~/.cache/zoxide.zsh


# eval "$(fzf --zsh)"
[[ ! -f ~/.cache/fzf.zsh ]] && fzf --zsh > ~/.cache/fzf.zsh
source ~/.cache/fzf.zsh


[[ -f ~/.cache/ssh-hosts ]] || awk '/^[Hh]ost / {for(i=2;i<=NF;i++) if($i!~/[*?]/) print $i}' ~/.ssh/config > ~/.cache/ssh-hosts 2>/dev/null
zstyle ':completion:*:ssh:*' hosts-ports false
zstyle ':completion:*:scp:*' hosts-ports false
[[ -f ~/.cache/ssh-hosts ]] && zstyle ':completion:*:(ssh|scp|sftp):*' hosts ${(f)"$(<~/.cache/ssh-hosts)"}

### END Zinit's Config }}}

#export C_INCLUDE_PATH=/home/junyi/.HHD/MyResource/C_Programming_Language/my_grep:$C_INCLUDE_PATH

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
   # export EDITOR="$HOME/bin/vi"
# else
  export EDITOR='nvim'
# fi

export SSH_KEY_PATH="$HOME/.ssh/rsa_id"

export GPG_TTY=$TTY

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[ -f ~/.config/zsh/p10k.zsh ] && source ~/.config/zsh/p10k.zsh

alias ls='eza --icons --hyperlink --classify --git-ignore --smart-group --group-directories-first --time-style=relative'
alias la='ls -a'                    # 显示隐藏文件 (all)
alias ll='ls -l --git'     # long format，显示 git 状态和列标题
alias l1="command ls -1t | grep -v '/\$' | head -1"

# note
# find -name *.java -print0 | xargs -0 p4 add
# 它的工作原理是，find 命令在目录树下找到所有的以 ".java" 结尾的文件，把它们用NULL字符隔开做成一个字符串，然后交给 xargs。
#
# 比如我要删除所有 *.java
# find -name *.java -print0 | xargs -0 rm

# time 命令格式
# export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

todo() {
 echo "$2" | /usr/bin/mail -s "$1 #quick" $TICKTICKEMAIL
}

# https://www.reddit.com/r/kde/comments/asseoc/how_to_hide_qfilesystemwatcherremovepaths_list_is/
export QT_LOGGING_RULES='*=false'

alias _zlua=z

d() {
	cd -$(dirs -v | fzf | cut -f1)
}

export RIPGREP_CONFIG_PATH=$HOME/.config/ripgrep/ripgreprc

# https://archive.zhimingwang.org/blog/2015-09-21-zsh-51-and-bracketed-paste.html
autoload -Uz bracketed-paste-url-magic
zle -N bracketed-paste bracketed-paste-url-magic

# zsh 5.1+ uses bracketed-paste-url-magic
if [[ $ZSH_VERSION =~ '^[0-4]\.' || $ZSH_VERSION =~ '^5\.0\.[0-9]' ]]; then
  autoload -Uz url-quote-magic
  zle -N self-insert url-quote-magic
  toggle-uqm () {
    if zle -l self-insert; then
      zle -A .self-insert self-insert && zle -M "switched to self-insert"
    else
      zle -N self-insert url-quote-magic && zle -M "switched to url-quote-magic"
    fi
  }
  zle -N toggle-uqm
  bindkey '^X$' toggle-uqm
fi

# zle -N zle-line-init
# zle -N zle-keymap-select

# vi-mode ESC 延迟修正: 默认 40 (400ms), 等待区分 lone ESC vs escape 序列开头
# 10ms 已足够终端把多字节序列一次性送达, 实测不会误把方向键拆开
KEYTIMEOUT=1

export GTAGSLABEL=native-pygments
# export GTAGSLABEL=native
# export CSCOPE_DB=GTAGS

# 让 gtags 把 *.h 视为 cpp 文件
# export GTAGSFORCECPP=

# http://www.crazylaw.cn/2018/11/15/linux-shell-huanhangbuchong/
# oh-my-zsh 换行补偿
# PROMPT_EOL_MARK=''


# 自动在项目目录的 .venv 目录创建虚拟环境
# export PIPENV_VENV_IN_PROJECT=1

# Zsh 可以通过 hash -d short=long 来设置一个 shortcut ，之后就可以用 ~short 的语法访问 long 路径，算是 home 目录 tilde 语法的延伸，非常方便。
# 不仅如此，在 powerlevel10k 等一些 theme 里，如果你的当前路径有对应 shortcut，那么它就会使用 shortcut 显示。
# 同时你自己也可以实现这个功能，通过 ${(D)path_var} 获取 $path_var 变量里所存路径的 shortcut。
# 注意 Zsh 在这里的 for 可以省略 do 和 done 。后面还会用到更多可选写法，详情可见 Zsh 文档。

hash -d config=$XDG_CONFIG_HOME
hash -d cache=$XDG_CACHE_HOME
hash -d data=$XDG_DATA_HOME
hash -d zdot=$ZDOTDIR
hash -d nvi=$XDG_CONFIG_HOME/nvim

hash -d app=$XDG_DATA_HOME/applications

# hash -d OneDrive=~/OneDrive
# hash -d Downloads=~/Downloads
# hash -d WorkSpace=~/WorkSpace
# for p in ~/WorkSpace/*; hash -d $(basename $p)=$p

# 按空格键时自动进行历史扩展
bindkey " " magic-space
# 直接执行历史扩展的结果 (任何选项直接加 no 就是相反效果) (或者用 unsetopt)
# setopt no_hist_verify
unsetopt hist_verify
setopt extendedglob

# systemd-journal 格式, 折行
# export SYSTEMD_LESS=FRXMK journalctl

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
[[ -n $MATLAB ]] && export PATH="$MATLAB/bin:$PATH"
export PATH=/home/junyi/.julia/bin:$PATH

# https://stackoverflow.com/questions/7561509/how-to-add-include-and-lib-paths-to-configure-make-cycle
export C_INCLUDE_PATH=$HOME/.local/include
export CPLUS_INCLUDE_PATH=$HOME/.local/include

export NPM_CONFIG_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/npm"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/npm"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc"
export PATH="$HOME/.local/share/npm/bin/:$PATH"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

umask 002

