# 虚拟机
# sudo virsh list
# sudo virsh start archlinux
# sudo virsh shutdown archlinux
alias v='sudo -E virsh'

alias cpuf='cat /proc/cpuinfo | grep MHz | cut -f2 -d: | uniq -'
alias psmem="ps axch -o cmd:15,%mem --sort=-%mem | head"
alias pscpu="ps axch -o cmd:15,%cpu --sort=-%cpu | head"

alias zshcfg="vi ~/.zshrc"
alias tmuxcfg="vi ~/.tmux.conf"
alias ta='tmux attach -t'
alias tad='tmux attach -d -t'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias tksv='tmux kill-server'
alias tkss='tmux kill-session -t'

# https://stackoverflow.com/questions/246215/how-can-i-generate-a-list-of-files-with-their-absolute-path-in-linux
alias fa='find ~+'

# alias okular='XDG_CONFIG_HOME=/home/junyi/okularconfig okular'
# alias inkscape='XDG_CONFIG_HOME=/home/junyi/ankiconfig inkscape'

# alias matlab='unset GTK_MODULES && env MESA_LOADER_DRIVER_OVERRIDE=i965 && matlab'
# alias matlab='screen -S matlab -m sh -c "/opt/MATLAB/R2018a/bin/matlab -nodesktop -nosplash"'
alias mrun="env MESA_LOADER_DRIVER_OVERRIDE=iHD matlab -nodesktop -nosplash -logfile `date +%Y_%m_%d-%H_%M_%S`.log -r"
# matlab tmux 布局
alias tmatlab='tmux -f ~/.tmux/scripting/matlab.conf attach'

# session 名字为 Julia; 窗口名为 main; 其中 `-d`：分离（detach）新的会话，使其在后台运行。
# 水平分割 pane
# 第一个窗口第2个 pane 执行命令 'cd ~/WorkSpace/drafts && julia' C-m
# 第一个窗口第1个 pane 执行命令
# 选择第一个 pane
alias tjulia='tmux new-session -s Julia -n main -c ~/WorkSpace/drafts -d && tmux split-window -h -t Julia && tmux send-keys -t Julia:1.2 "cd ~/WorkSpace/drafts  && julia --project=." C-m && tmux send-keys -t Julia:1.1 "vim test.jl" C-m && tmux select-pane -t 1 && tmux attach -t Julia'

# alias kjulia='kitty --session ~/.config/kitty/sessions/julia.conf --title \"Julia Development\"'


kjulia() {
    # 声明局部变量，避免污染全局命名空间
    local julia_id

    cd ~/WorkSpace/drafts
    kitten @ set-tab-title "Julia Development"
    
    # 在当前窗口右侧创建垂直分割，启动 Julia REPL
    # --location=vsplit: 垂直分割（左右布局）
    # --cwd: 设置工作目录
    # --keep-focus: 保持焦点在左侧窗口（vim 所在窗口）
    # --project=.: 使用当前目录的 Julia 项目环境
    # 命令返回新创建窗口的 ID，保存到 julia_id 变量
    julia_id=$(kitten @ launch --location=vsplit --cwd=~/WorkSpace/drafts --keep-focus julia --project=.)
    
    # 启动 vim 并预配置 vim-slime
    # -c: 在启动时执行 vim 命令
    # g:slime_default_config: 全局配置，对所有 buffer 生效
    #   - window_id: 指定目标窗口为刚创建的 Julia 窗口
    #   - listen_on: kitty 监听地址，留空表示使用当前 kitty 实例
    # g:slime_dont_ask_default: 不询问配置，直接使用默认值
    vim -c "let g:slime_default_config={'window_id':$julia_id,'listen_on':''}" \
        -c "let g:slime_dont_ask_default=1" \
        test.jl
}

# 合并其他窗口的 tab 到当前窗口（使用 fzf 选择）
kmerge() {
    # 获取所有其他 kitty 窗口的 tabs，格式化为: tab_id | os_window_id | title
    local tab_info=$(kitten @ ls | jq -r '
        .[] | .tabs[] |
        "\(.id)|\(.os_window_id)|\(.title)"
    ' | fzf --delimiter='|' --with-nth=3 --prompt="Select tab to merge: ")

    if [ -n "$tab_info" ]; then
        local tab_id=$(echo "$tab_info" | cut -d'|' -f1)
        kitten @ detach-tab --target-tab id:$tab_id
    fi
}

# 或者简化版：直接通过 title 匹配
kmerge-by-title() {
    local title="$1"
    if [ -z "$title" ]; then
        echo "Usage: kmerge-by-title <title>"
        return 1
    fi

    local tab_id=$(kitten @ ls | jq -r --arg title "$title" '
        .[] | .tabs[] |
        select(.title == $title) | .id
    ' | head -1)

    if [ -n "$tab_id" ]; then
        kitten @ detach-tab --target-tab id:$tab_id
        echo "Merged tab: $title (id: $tab_id)"
    else
        echo "Tab not found: $title"
    fi
}

alias weather='curl wttr.in'
# youtube-dl and you-get
alias yd='youtube-dl --write-auto-sub --sub-lang en'
alias yden='youtube-dl --write-sub --sub-lang en'
alias ydcn='youtube-dl --write-sub --sub-lang zh-CN'

alias mkcd='foo(){ mkdir -p "$1"; cd "$1"  }; foo '
alias rd='rmdir'
alias u='chevereto_upload.py -c ~/.config/chevereto/config.json -s'

alias sagenotes='cd ~/Desktop/learning/learning_python3/sage_files && jupyter lab --no-browser'
alias jl="julia --startup-file=no --banner=no"
alias j.="julia --banner=no --project=."
alias j..="julia --banner=no --project=.."
gvimt(){ command gvim --remote-tab-silent $@ || command gvim $@; }
alias jc='journalctl'
alias jcu='journalctl --user'
alias sc='systemctl'
alias sc-hibernate='systemctl hibernate'
alias sc-suspend-then-hibernate='systemctl suspend-then-hibernate'
alias sc-suspend='systemctl suspend'


# edit
# https://bbs.archlinux.org/viewtopic.php?id=240765 edit 要用 /usr/bin/systemctl 绝对路径
alias sce='sudo -E /usr/bin/systemctl edit --full'
alias scu='systemctl --user'
# edit
alias scue='/usr/bin/systemctl --user edit --full'

alias reboot='systemctl reboot'
alias poweroff='systemctl poweroff'

# alias vim='vim --cmd "let g:isProgramming=1" '
# alias vim='vim --cmd "let g:isProgramming=1" '
# alias nvi='LANG=en_US.UTF-8 nvim'
alias wiki='vi -c "cd %:h" ~/Notes/index.md'
alias diary='vi -c "cd %:h" ~/Notes/diary/$(date +"%F").md'  # date +"%F" 的意思：eg: 2020-08-05


# plasmashell cpu占用过高，重启解决
alias restartplasmashell='kquitapp6 plasmashell ; kstart6 plasmashell'
alias plasmashellrestart='kquitapp6 plasmashell ; kstart6 plasmashell'

alias makebeamer='pandoc -t beamer -o makefile_demo.pdf --pdf-engine=xelatex makefile.md'

alias notes='cd ~/Desktop/university/current_course && $EDITOR main.tex'
alias vitodo='vi ~/Notes/todolist.md'

alias unzip='unzip -O GBK'

alias svi='sudo -E vim --cmd "let g:SUDO=1" --cmd "let g:isPlain=1" '
# 088.987  000.001: --- VIM STARTED --- 启动 只需要 88 毫秒
alias vi='vim --cmd "let g:isPlain=1"'
# alias vim='vim --cmd "let g:CoC=1" --cmd "let g:isPlain=0"'
alias vim='vim --cmd "let g:isPlain=0"'
# alias nvim='vim --cmd "let g:CoC=1" --cmd "let g:isPlain=0"'
# alias nvim='nvim --cmd "let g:isPlain=0"'
# 打开到 上一次 打开的地方
alias lvi='vi -c "normal '\''0"'

# For git front-end: vim-fugitive
alias vig='vi --cmd "let g:usingGit=1" -c "G" -c "only"'
alias vit='vim --servername TEX'
alias gvit='gvim --servername TEX --cmd "let g:isPlain=0"'
alias vitv='vim --servername TEX -c 'VimtexView''
alias gvitv='gvim --servername TEX --cmd "let g:isPlain=0" -c 'VimtexView''
alias testtex="cd ~/Desktop/university/testtex && gvim --servername TEX --cmd "let g:isPlain=0" -c 'VimtexView' main.tex"
# 打开 jupyter qtconsole
alias jvi="vim -c JupyterConnect"
# alias jvi="jupyter qtconsole& ; vim -c JupyterConnect"

# Show open ports
# alias ports='netstat -tulanp'
alias ports='netstat -lntp'

# alias ssh='ssh -Y'
alias sshphone='ssh -p8022 _gateway'
alias pb='curl -F sunset=1200 -F "c=@-" "http://8.140.148.238:10002"'


#alias rsync='myrsync.sh'
alias vicmake='$EDITOR CMakeLists.txt'
alias vimcmake='$EDITOR CMakeLists.txt'

(( $+commands[you-get] )) && alias you-getp="you-get -p mpv"
#alias cat='bat'
alias turbo='sudo sh -c "echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo"'
alias no_turbo='sudo sh -c "echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo"'
alias top='htop'
# alias sudo='sudo -E'
# alias pacman='powerpill'

alias -s php=vim
alias -s rb=vim
alias -s c=vim
alias -s cpp=vim
alias -s md=vim
alias -s tex='vim --servername TEX'
alias -s pdf=okular

# git
alias gbb='git for-each-ref --sort=-committerdate refs/heads/ --format="%(color:green)%(committerdate:format:%Y-%m-%d %H:%M)%(color:reset) %(color:blue)%(refname:short)%(color:reset) %(subject)"'
alias gpp='git add . && git commit -m "update" && git push'
alias gc1='git clone --depth=1 '
alias gtree="git log --graph --pretty=format:'%C(yellow)%h%C(cyan)%d%Creset %Cgreen%an%Creset: %s %Cblue(%ad)%Creset'"
alias gxtree="git log --graph --pretty=format:'%C(yellow)%h%C(cyan)%d%Creset %Cgreen%an%Creset: %s %Cblue(%ar)%Creset'"
alias greftree="git reflog --pretty=format:'%C(yellow)%h%C(cyan)%d%Creset %Cgreen%gn%Creset: %gs %Cblue(%gd)%Creset' --date=iso"
alias grefxtree="git reflog --pretty=format:'%C(yellow)%h%C(cyan)%d%Creset %Cgreen%gn%Creset: %gs %Cblue(%gd)%Creset' --date=relative"
alias gfetched-xtree='git xtree @{1}..'

if [[ -f /proc/version ]]
then
if grep -q "archlinux" /proc/version
    then
	alias Syu='sudo pacman -Syu'
	alias S='sudo pacman -S'
	alias Si='pacman -Si'
	alias Ss='pacman -Ss'
	alias R='sudo pacman -Rs'
	alias Qi='pacman -Qi'
	alias Ql='pacman -Ql'
	alias Qs='pacman -Qs'
	alias Qsq='pacman -Qsq'
	alias Qm='pacman -Qm'
	alias Qmq='pacman -Qmq'
	alias Qk='pacman -Qk'
	alias Qkk='pacman -Qkk'
	alias Qo='pacman -Qo'
	alias F='pacman -F'
	alias Fl='pacman -Fl'
elif grep -qE "(debian|ubuntu)" /proc/version || command -v apt >/dev/null 2>&1
then
	alias Syu='sudo apt update && sudo apt upgrade'
	alias S='sudo apt install'
	alias Si='apt show'
	alias Ss='apt search'
	alias R='sudo apt autoremove'
	alias Qi='dpkg -s'
	alias Ql='dpkg -L'
	alias Qs='dpkg -l | grep'
	alias Qsq='dpkg-query -f "\${binary:Package}\n" -W'
	alias Qm='apt list --installed | grep ",local"'
	alias Qmq='apt-mark showmanual'
	alias Qk='debsums -c'
	alias Qkk='debsums'
	alias Qo='dpkg -S'
	alias F='apt-file search'
	alias Fl='apt-file list'
fi
else
	# for termux
	alias S='pkg install'
	alias Ss='pkg search'
fi

# Note for rsync:
# -a for --archive
# -v for --verbose
# -z for --compress
# -h for --human-readable
# -P same as --partial --progress
alias rsync-copy="rsync -avzP -h --exclude=__pycache__"
alias rsync-move="rsync -avzP -h --remove-source-files"
alias rsync-update="rsync -avzuP -h --exclude=__pycache__"
alias rsync-synchronize="rsync -avzuP --delete -h --exclude=__pycache__"

alias git-ls="\\ls -A --group-directories-first -1 | while IFS= read -r line; do git log --color --format=\"\$(\\ls -d -F --color \"\$line\") =} %C(bold black)▏%Creset%Cred%h %Cgreen(%cr)%Creset =} %C(bold black)▏%Creset%s %C(bold blue)<%an>%Creset\" --abbrev-commit --max-count 1 HEAD -- \"\$line\"; done | awk -F'=}' '{ nf[NR]=NF; for (i = 1; i <= NF; i++) { cell[NR,i] = \$i; gsub(/\\033\\[([[:digit:]]+(;[[:digit:]]+)*)?[mK]/, \"\", \$i); len[NR,i] = l = length(\$i); if (l > max[i]) max[i] = l; } } END { for (row = 1; row <= NR; row++) { for (col = 1; col < nf[row]; col++) printf \"%s%*s%s\", cell[row,col], max[col]-len[row,col], \"\", OFS; print cell[row,nf[row]]; } }'"
alias 1='cd -'


# KDE 混成器
# 手动开关混成器
# 有时混成器会因为某些原因需要手动开启或关闭，但是目前在 KDE 下混成器在设置里无法在不关机的情况下直接关闭，下面命令提供手动开关混成器的效果
alias stopCompositor='qdbus org.kde.KWin /Compositor suspend'  #禁用
alias startCompositor='qdbus org.kde.KWin /Compositor resume'   #开启


alias copy='wl-copy'
alias open='xdg-open'
alias o='xdg-open'
alias screenshot='flameshot gui -r'

alias fzfp="fzf --preview 'bat --color=always --style=header,grid --line-range :300 {}'"

h() {
    local lines=10

    # 解析 -n 参数
    if [[ "$1" =~ ^-[0-9]+$ ]]; then
        lines="${1#-}"
        shift
    fi

    # 如果只显示1行，不要行号；否则显示行号
    if [[ $lines -eq 1 ]]; then
        bat --style=plain --line-range ":$lines" "$@"
    else
        bat --style=numbers --line-range ":$lines" "$@"
    fi
}
