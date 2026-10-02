unsetopt beep # 不需要打 cd，直接进入目录
setopt autocd # 自动记住已访问目录栈
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_minus
# rm * 时不要提示
setopt rm_star_silent
# 允许在交互模式中使用注释
setopt interactive_comments
# disown 后自动继续进程
setopt auto_continue
setopt extended_glob
# 单引号中的 '' 表示一个 ' （如同 Vimscript 中者）
setopt rc_quotes
# 补全列表不同列可以使用不同的列宽
setopt listpacked
# 补全 identifier=path 形式的参数
setopt magic_equal_subst
# 为方便复制，右边的提示符只在最新的提示符上显示
setopt transient_rprompt
# setopt 的输出显示选项的开关状态
# setopt ksh_option_print # claude code 报错 /tmp/claude-shell-snapshot-451d:setopt:7180: no such option: off
setopt no_bg_nice
setopt noflowcontrol
# stty -ixon # 上一行在 tmux 中时常不起作用
# 历史记录
# 不保存重复的历史记录项
setopt hist_save_no_dups
setopt hist_ignore_dups
# setopt hist_ignore_all_dups
# 在命令前添加空格，不将此命令添加到记录文件中
setopt hist_ignore_space
# zsh 4.3.6 doesn't have this option
setopt hist_fcntl_lock 2>/dev/null
# 不要自作聪明，我需要通配符
unsetopt nomatch
