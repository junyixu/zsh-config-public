# xargs -r 表示 如果为空，那么什么都不做
# vim 用 xargs 需要用 -o 选项 详情见
# https://superuser.com/questions/336016/invoking-vi-through-find-xargs-breaks-my-terminal-why
se() { du -a ~/bin/* ~/.config/* | awk '{ print $2 }'  | fzf --preview 'bat --style=numbers --color=always {} | head -33' | xargs -ro $EDITOR; }

visearch() { baloosearch $1 | fzf --preview 'bat --style=numbers --color=always {} | head -33' | xargs -ro $EDITOR; }

etc() { du -a /etc/* | awk '{ print $2 }'  | fzf --preview 'bat --style=numbers --color=always {} | head -33' | xargs -ro $EDITOR; }
# system() { du -a ~/.config/systemd/user/* /etc/systemd/* /usr/lib/systemd/* | awk '{ print $2 }'  | fzf | xargs -ro $EDITOR; }
# vim 用 xargs 必须要有 -o, 这是 vim 的 bug
sd() { 
	__sd_filename=$(find -H ~/.config/systemd /etc/systemd /usr/lib/systemd -type f \(  -name '*.timer' -o -name '*.service' \) | fzf --preview 'bat --style=numbers --color=always {} | head -33')
	# if [[ $__sd_filename == $HOME* ]]; then  # 使用 $HOME 通配符, [[ ]] 里面可以使用字符串比较的高级特性
	#    $EDITOR $__sd_filename
	# else
	# 	sudo -E $EDITOR $__sd_filename
    # fi
	[[ $__sd_filename != "" ]] &&	 ([[ $__sd_filename == $HOME* ]] && $EDITOR $__sd_filename || sudo -E $EDITOR $__sd_filename)  # 使用 $HOME 通配符, [[ ]] 里面可以使用字符串比较的高级特性
    # __sd_filename 一旦设置，出了函数也还在，需要用 unset 消除
	unset __sd_filename
}

fnotes(){
	local __current_working_dir
	local __note_name
	local __note_dir
	local __note_dir_name
	__current_working_dir=$(pwd)
	cd ~/.cache/LaTeXNotesPDFImg
	__note_name=$(ls ./* | fzfimg.sh)
	if [[ $__note_name != "" ]]; then
		__note_name=$(basename $__note_name .jpg)
		__note_dir_name=$HOME/Desktop/university/bachelor-3
		 __note_dir=$__note_dir_name/$__note_name
		cd $__note_dir
		vim --servername TEX -c 'VimtexView' ./main.tex
	else
		cd $current_working_dir
		echo '字符串为空，没有选择任何pdf文件'
	fi
}

    # local __DEFAULT_SIZE="1920x1080"
	# pdftoppm -f 1 -l 1 \
			 # -scale-to-x "${__DEFAULT_SIZE%x*}" \
			 # -scale-to-y -1 \
			 # -singlefile \
			 # -jpeg -tiffcompression jpeg \
			 # -- "$__note_dir/latex.out/main.pdf" "$HOME/.cache/LaTeXNotesPDFImg/$__note_dir_name" 

# fstart - start systemd unit
fstart() {
  unit=$(systemctl list-unit-files | grep disabled |
    awk '{print $1}' | grep service | fzf)
  [ -n "$unit" ] && sudo systemctl start $unit &&
    journalctl -u $unit --since "10 sec ago" --no-pager
}

# fstop - stop systemd unit
fstop() {
  unit=$(systemctl list-units | grep running |
    awk '{print $1}' | grep service | fzf)
  [ -n "$unit" ] && sudo systemctl stop $unit &&
    journalctl -u $unit --since "10 sec ago" --no-pager
}

# finstall - install new package
finstall() {
  package=$(pacman -Ssq | fzf)
  if [ -n "$package" ]; then
    pacman -Ss "^$package$"
    sudo pacman -S $package
  fi
}

# fdelete - completely uninstall package
fdelete() {
  package=$(pacman -Qqe | fzf)
  [ -n "$package" ] && sudo pacman -Rscn $package
}

fkill() {
    local pid
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi
}

# 搜索pdf笔记中的内容
searchnotes() {
	# 让 awk 用 冒号 : 分隔
	okular $(rga $@ ~/Sync/uni_pdf | fzf | awk -F: '{print $2, $1}' | sed s/Page/--page/) --find $@
}

# 搜索Latex笔记的内容
searche() {
	# 让 awk 用 冒号 : 分隔
	what_i_got=$(rga $@ ~/Documents/Sync/uni_pdf/*.pdf | fzf)
	if [ ! -z $what_i_got  ]; then # 判断字符串是否为空，若不为空，则：
		okular $(echo $what_i_got | awk -F: '{print $2, $1}' | sed s/Page/--page/) --find $@
	fi
}

# 搜索当前目录 pdf 中的内容
searchpdf() {
	# 让 awk 用 冒号 : 分隔
	okular $(rga $@ | fzf | awk -F: '{print $2, $1}' | sed s/Page/--page/) --find $@
}

# 不行，-- 的作用
# s() {
# 	local __note_page_name
# 	# 让 awk 用 冒号 : 分隔
# 	__note_page_name=$(rga $@ ~/Sync/uni_pdf | fzf | awk -F: '{print $2, $1}' | sed s/Page/--page/)
# 	echo $__note_page_name
# 	if [ ! -z $__note_page_name ]; then  # 判断字符串是否为空，若不为空，则：
# 		okular $__note_page_name
# 	else # 若字符串为空，则
# 		echo '字符串为空，没有选择任何pdf文件'
# 	fi
# }

t() {
	local __current_working_dir
	local __note_name
	__current_working_dir=$(pwd)
	cd ~/.cache/LaTeXNotesPDFImg  # TODO fzfimg.sh 必须 cd 到那个目录，如何修改使之不需要 cd 到那个目录？
	__note_name=$(ls ./* | fzfimg.sh)

	if [ ! -z $__note_name ]; then  # 判断字符串是否为空，若不为空，则：
	# 用 sed 去掉 开头的     数字 , . /
	# 用 sed 去掉末尾的      .jpg
	xdg-open ~/Sync/uni_pdf/$__note_name:r.pdf || echo '没有这个文件'
	else # 若字符串为空，则
		cd $__current_working_dir
		echo '字符串为空，没有选择任何pdf文件'
	fi
}

tt() {
	local __current_working_dir
	local __note_name
	__current_working_dir=$(pwd)
	cd ~/.cache/LaTeXNotesPDFImg  # TODO fzfimg.sh 必须 cd 到那个目录，如何修改使之不需要 cd 到那个目录？
	__note_name=$(ls ./* | fzfimg.sh)

	if [ ! -z $__note_name ]; then  # 判断字符串是否为空，若不为空，则：
	# 用 sed 去掉 开头的     数字 , . /
	# 用 sed 去掉末尾的      .jpg
	_zlua "$(echo $__note_name | sed 's/^[0-9,.\/]* *//' | sed 's/\.jpg$//')" && gvim --servername TEX --cmd "let g:isPlain=0" -c 'VimtexView' ./main.tex || echo '没有这个目录'
	else # 若字符串为空，则
		cd $__current_working_dir
		echo '字符串为空，没有选择任何pdf文件'
	fi
}


tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}
rf() {
    if [[ "$#" -ne 0 ]]; then
        ranger $(j $@)
        return
    fi
    ranger "$(j -l | sort -k1gr | awk '$1 ~ /[0-9]:/ && $2 ~ /^\// { for (i=2; i<=NF; i++) { print $(i) } }' |  fzf --height 40% --reverse --inline-info)"
}

fb() {
  local branches branch
  branches=$(git --no-pager branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

fco() {
  local tags branches target
  branches=$(
    git --no-pager branch --all \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  tags=$(
    git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  target=$(
    (echo "$branches"; echo "$tags") |
    fzf --no-hscroll --no-multi -n 2 \
        --ansi) || return
  git checkout $(awk '{print $2}' <<<"$target" )
}

fs() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" | \
    fzf --query="$1" --select-1 --exit-0) &&
  tmux switch-client -t "$session"
}
f() {
    sels=( "${(@f)$(fd "${fd_default[@]}" "${@:2}"| fzf)}" )
    test -n "$sels" && print -z -- "$1 ${sels[@]:q:q}"
}
# vf - fuzzy open with vim from anywhere
# ex: vf word1 word2 ... (even part of a file name)
# zsh autoload function
# fuzzy vi
fvi() {
  local files

  files=(${(f)"$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1 -m)"})

  	# -n 检测字符串长度是否不为 0，不为 0 返回 true
  if [[ -n $files ]]
  then
    vim -- $files
    print -l $files[1]
  fi
}

# 用 xdg-open 打开文件
# fuzzy open
fo() {
  local files

  files=(${(f)"$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1 -m)"})

  	# -n 检测字符串长度是否不为 0，不为 0 返回 true
  if [[ -n $files ]]
  then
     xdg-open $files
     print -l $files[1]
  fi
}


# cf - fuzzy cd from anywhere
# ex: cf word1 word2 ... (even part of a file name)
# zsh autoload function
# fuzzy cd
fcd() {
  local file
  file="$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1 --preview 'if [[ -d {} ]]; then ls -la --color=always {}; else bat --color=always --style=numbers --line-range=:100 {}; fi')"
  if [[ -n $file ]]
  then
     if [[ -d $file ]]
     then
        cd -- $file
     else
        cd -- ${file:h}
     fi
  fi
}

# https://github.com/phiresky/ripgrep-all
rga-fzf() {
  RG_PREFIX="rga --files-with-matches"
  local file
  file="$(
    FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
      fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
        --phony -q "$1" \
        --bind "change:reload:$RG_PREFIX {q}" \
        --preview-window="70%:wrap"
  )" &&
  echo "opening $file" &&
  xdg-open "$file"
}

# Google Chrome (OS X/linux)
chromec() {
  local cols sep google_history open
  cols=$(( COLUMNS / 3 ))
  sep='{::}'

  if [ "$(uname)" = "Darwin" ]; then
    google_history="$HOME/Library/Application Support/Google/Chrome/Default/History"
    open=open
  else
    google_history="$HOME/.config/chromium/Default/History"
    open=xdg-open
  fi
  cp -f "$google_history" /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url
     from urls order by last_visit_time desc" |
  awk -F $sep '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' |
  fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' | xargs $open > /dev/null 2> /dev/null
}

# b - browse chrome bookmarks
chromeb() {
     bookmarks_path=~/.config/chromium/Default/Bookmarks

     jq_script='
        def ancestors: while(. | length >= 2; del(.[-1,-2]));
        . as $in | paths(.url?) as $key | $in | getpath($key) | {name,url, path: [$key[0:-2] | ancestors as $a | $in | getpath($a) | .name?] | reverse | join("/") } | .path + "/" + .name + "\t" + .url'

    jq -r $jq_script < "$bookmarks_path" \
        | sed -E $'s/(.*)\t(.*)/\\1\t\x1b[36m\\2\x1b[m/g' \
        | fzf --ansi \
        | cut -d$'\t' -f2 \
        | xargs open
}

# Like f, but not recursive.
fm() f "$@" --max-depth 1

man-find() {
    f=$(fd . $MANPATH/man${1:-1} -t f -x echo {/.} | fzf) && man $f
}

fman() {
    man -k . | fzf --prompt='Man> ' | awk '{print $1}' | xargs -r man
}
