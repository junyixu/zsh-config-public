zinit ice wait'1' lucid; zinit snippet OMZ::plugins/systemd/systemd.plugin.zsh
srun-julia () {
    # --- 颜色定义 (柔和高亮) ---
    local GREEN='\033[32m' # 成功
    local RED='\033[31m'   # 错误
    local CYAN='\033[36m'  # 青色 (用于脚本/单元名)
    local BLUE='\033[34m'  # 蓝色 (用于路径/目录)
    local WHITE='\033[37m' # 白色/常规信息
    local NC='\033[0m'     # 重置颜色

    if [ -z "$1" ]; then
        echo -e "${RED}Usage:${NC} jrun ${CYAN}<script_file>${NC} [additional_julia_args...]"
        return 1
    fi

    local current_dir=$(pwd)
    local script_file="$1"
    local unit_name=$(basename "$script_file" .jl)
    local service_name="${unit_name}.service"
    local description="Julia Project Run: $script_file (in $current_dir)"

    shift

    # 1. 启动信息：只高亮脚本名和路径
    echo -e "${WHITE}Starting Julia job '${CYAN}${unit_name}${WHITE}' in directory: ${BLUE}${current_dir}${NC}"

    # --- 替代 --replace 的健壮性检查和清理 ---
    # 尝试停止和重置旧服务，确保 systemd 允许我们启动新任务
    systemctl --user stop "$service_name" 2>/dev/null
    systemctl --user reset-failed "$service_name" 2>/dev/null

    echo -e "${WHITE}Previous unit state cleared (if necessary).${NC}"
    # --------------------------------------------------

    # 核心 systemd-run 命令 (不包含 --replace)
    systemd-run \
        --user \
        --unit="$unit_name" \
        --description="$description" \
        --working-directory="$current_dir" \
        --property=Nice=10 \
        --property=IOSchedulingClass=idle \
        julia --project=. "$script_file" "$@"

    local run_status=$?

    if [ $run_status -eq 0 ]; then
        echo -e "${GREEN}Job started successfully.${NC}"
        echo -e "${WHITE}Running as unit: ${CYAN}${service_name}${NC}"

        # 2. 高亮状态检查命令
        echo -e "${WHITE}Check status with: ${GREEN}systemctl --user status ${CYAN}${unit_name}${NC}"

        # 3. 高亮日志检查命令
        echo -e "${WHITE}Check logs with: ${GREEN}journalctl --user -u ${CYAN}${unit_name}${NC}"
    else
        echo -e "${RED}Error: Failed to start systemd unit (Exit Code: $run_status).${NC}"
        # 如果启动失败，提示用户可能需要手动重置
        echo -e "${WHITE}If the unit failed previously, try resetting it manually:${NC}"
        echo -e "${WHITE}  ${GREEN}systemctl --user reset-failed ${CYAN}${unit_name}.service${NC}"
        return 1
    fi
}



srun-jupyter() {
    # --- 颜色定义 (柔和高亮) ---
    local GREEN='\033[32m' # 成功
    local RED='\033[31m'   # 错误
    local CYAN='\033[36m'  # 青色 (用于脚本/单元名)
    local BLUE='\033[34m'  # 蓝色 (用于路径/目录)
    local WHITE='\033[37m' # 白色/常规信息
    local NC='\033[0m'     # 重置颜色

    if [ -z "$1" ]; then
        echo -e "${RED}Usage:${NC} srun-jupyter ${CYAN}<notebook_file>${NC} [description]"
        echo -e "${WHITE}Example:${NC} srun-jupyter ${CYAN}anim_sin2.ipynb${NC} ${WHITE}\"jupyter lab for qmd\"${NC}"
        return 1
    fi

    local current_dir=$(pwd)
    local notebook_file="$1"
    local description="${2:-jupyter lab session}"
    local unit_name="jupyter"

    # 检查文件是否存在
    if [ ! -f "$notebook_file" ]; then
        echo -e "${RED}Error:${NC} File '${CYAN}${notebook_file}${NC}' not found in ${BLUE}${current_dir}${NC}"
        return 1
    fi

    # 1. 启动信息：高亮文件名和路径
    echo -e "${WHITE}Starting Jupyter Lab with '${CYAN}${notebook_file}${WHITE}' in directory: ${BLUE}${current_dir}${NC}"

    # --- 替代 --replace 的健壮性检查和清理 ---
    # 尝试停止和重置旧服务，确保 systemd 允许我们启动新任务
    systemctl --user stop "$unit_name" 2>/dev/null
    systemctl --user reset-failed "$unit_name" 2>/dev/null

    echo -e "${WHITE}Previous Jupyter unit state cleared (if necessary).${NC}"
    # --------------------------------------------------

    # 核心 systemd-run 命令
    systemd-run \
        --user \
        --unit="$unit_name" \
        --description="$description" \
        --working-directory="$current_dir" \
        jupyter lab "$notebook_file"

    local run_status=$?

    if [ $run_status -eq 0 ]; then
        echo -e "${GREEN}Jupyter Lab started successfully.${NC}"
        echo -e "${WHITE}Running as unit: ${CYAN}${unit_name}.service${NC}"

        # 2. 高亮状态检查命令
        echo -e "${WHITE}Check status with: ${GREEN}systemctl --user status ${CYAN}${unit_name}${NC}"

        # 3. 高亮日志检查命令
        echo -e "${WHITE}Check logs with: ${GREEN}journalctl --user -u ${CYAN}${unit_name}${NC}"
    else
        echo -e "${RED}Error: Failed to start Jupyter Lab systemd unit (Exit Code: $run_status).${NC}"
        # 如果启动失败，提示用户可能需要手动重置
        echo -e "${WHITE}If the unit failed previously, try resetting it manually:${NC}"
        echo -e "${WHITE}  ${GREEN}systemctl --user reset-failed ${CYAN}${unit_name}.service${NC}"
        return 1
    fi
}

srun-quarto() {
    # --- 颜色定义 (柔和高亮) ---
    local GREEN='\033[32m' # 成功
    local RED='\033[31m'   # 错误
    local CYAN='\033[36m'  # 青色 (用于脚本/单元名)
    local BLUE='\033[34m'  # 蓝色 (用于路径/目录)
    local WHITE='\033[37m' # 白色/常规信息
    local NC='\033[0m'     # 重置颜色

    if [ -z "$1" ]; then
        echo -e "${RED}Usage:${NC} srun-quarto ${CYAN}<qmd_file>${NC} [description]"
        echo -e "${WHITE}Example:${NC} srun-quarto ${CYAN}anim_sin.qmd${NC} ${WHITE}\"quarto preview session\"${NC}"
        return 1
    fi

    local current_dir=$(pwd)
    local qmd_file="$1"
    local description="${2:-quarto preview session}"
    local unit_name="quarto"

    # 检查文件是否存在
    if [ ! -f "$qmd_file" ]; then
        echo -e "${RED}Error:${NC} File '${CYAN}${qmd_file}${NC}' not found in ${BLUE}${current_dir}${NC}"
        return 1
    fi

    # 1. 启动信息：高亮文件名和路径
    echo -e "${WHITE}Starting Quarto Preview with '${CYAN}${qmd_file}${WHITE}' in directory: ${BLUE}${current_dir}${NC}"

    # --- 替代 --replace 的健壮性检查和清理 ---
    # 尝试停止和重置旧服务，确保 systemd 允许我们启动新任务
    # systemctl --user stop "$unit_name" 2>/dev/null
    # systemctl --user reset-failed "$unit_name" 2>/dev/null

    # echo -e "${WHITE}Previous Quarto unit state cleared (if necessary).${NC}"
    # --------------------------------------------------

    # 核心 systemd-run 命令
    # 设置环境变量，确保 julia 能被找到（~/.local/bin 路径）
    systemd-run \
        --user \
        --unit="$unit_name" \
        --description="$description" \
        --working-directory="$current_dir" \
        quarto preview "$qmd_file"

    local run_status=$?

    if [ $run_status -eq 0 ]; then
        echo -e "${GREEN}Quarto Preview started successfully.${NC}"
        echo -e "${WHITE}Running as unit: ${CYAN}${unit_name}.service${NC}"

        # 2. 高亮状态检查命令
        echo -e "${WHITE}Check status with: ${GREEN}systemctl --user status ${CYAN}${unit_name}${NC}"

        # 3. 高亮日志检查命令
        echo -e "${WHITE}Check logs with: ${GREEN}journalctl --user -u ${CYAN}${unit_name}${NC}"
    else
        echo -e "${RED}Error: Failed to start Quarto Preview systemd unit (Exit Code: $run_status).${NC}"
        # 如果启动失败，提示用户可能需要手动重置
        echo -e "${WHITE}If the unit failed previously, try resetting it manually:${NC}"
        echo -e "${WHITE}  ${GREEN}systemctl --user reset-failed ${CYAN}${unit_name}.service${NC}"
        return 1
    fi
}

# 智能的 srun 命令，根据文件后缀自动选择合适的运行方式
# 支持的文件类型：
# - .ipynb: 使用 jupyter lab 打开
# - .qmd: 使用 quarto preview 打开
# 用法: srun <file> [description]
srun() {
    if [ -z "$1" ]; then
        echo "Usage: srun <file> [description]"
        echo "Supported file types:"
        echo "  .ipynb - Jupyter Notebook files"
        echo "  .qmd   - Quarto Markdown files"
        echo "Examples:"
        echo "  srun notebook.ipynb \"jupyter lab session\""
        echo "  srun document.qmd \"quarto preview session\""
        return 1
    fi

    local file="$1"
    local description="${2:-auto-detected session}"

    # 检查文件是否存在
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found in $(pwd)"
        return 1
    fi

    # 根据文件后缀选择合适的运行方式
    case "$file" in
        *.ipynb)
            echo "Detected Jupyter Notebook file. Using srun-jupyter..."
            srun-jupyter "$file" "$description"
            ;;
        *.qmd)
            echo "Detected Quarto Markdown file. Using srun-quarto..."
            srun-quarto "$file"
            ;;
        *)
            echo "Error: Unsupported file type for '$file'"
            echo "Supported extensions: .ipynb, .qmd"
            echo "Tip: Use srun-jupyter or srun-quarto directly for specific commands."
            return 1
            ;;
    esac
}


alias sr='systemd-run --user --scope'

# ---- 内部辅助：由 PWD 生成 socket 路径和 unit name ----
_nvi_socket() {
    # 用 $XDG_RUNTIME_DIR（tmpfs、per-user、登出清理）
    print -r -- "${XDG_RUNTIME_DIR:-/tmp}/nvim${PWD//\//-}.sock"
}

_nvi_unit() {
    # unit name = basename + 完整路径的短 hash，避免同名目录冲突
    # cksum 用 POSIX util,不引入依赖
    local hash
    hash=$(print -rn -- "$PWD" | cksum | awk '{print $1}')
    print -r -- "nvim-server-$(systemd-escape "${PWD:t}")-${hash}"
}

# ---- attach UI,或 fallback 到普通 nvim ----
nvi() {
    local socket=$(_nvi_socket)
    if [[ -S "$socket" ]]; then
        LANG=C.UTF-8 nvim --server "$socket" --remote-ui
    else
        LANG=C.UTF-8 nvim "$@"
    fi
}

# ---- 启动 headless server ----
nvi-server() {
    local socket=$(_nvi_socket)
    local unit=$(_nvi_unit)
    local desc="headless nvim @ ${PWD:t}"
    (( $# )) && desc="${desc} [$*]"

    # 已经在跑:直接告诉用户怎么连
    if systemctl --user --quiet is-active "$unit"; then
        echo "already running: $unit" >&2
        echo "  attach: nvi" >&2
        echo "  stop:   nvi-stop" >&2
        return 1
    fi

    # --setenv=NAME (省略 =VALUE) 从 systemd-run 自身进程环境取值,
    # 即当前交互 zsh 的环境 —— 这样 rc 里加的 PATH、已激活的 venv 等
    # 能带进 unit; 否则只继承 systemd --user manager 的裸环境。
    systemd-run --user \
        --unit="$unit" \
        --description="$desc" \
        --working-directory="$PWD" \
        --setenv=LANG=C.UTF-8 \
        --setenv=PATH \
        --setenv=VIRTUAL_ENV \
        --setenv=CONDA_PREFIX \
        --setenv=MAMBA_ROOT_PREFIX \
        --setenv=JULIA_CONDAPKG_BACKEND \
        --setenv=JULIA_PYTHONCALL_EXE \
        --setenv=RIPGREP_CONFIG_PATH \
        --setenv=NPM_CONFIG_PREFIX \
        --setenv=C_INCLUDE_PATH \
        --setenv=CPLUS_INCLUDE_PATH \
        --setenv=GTAGSLABEL \
        nvim --headless --listen "$socket" "$@"
}

# ---- 停止当前目录的 server,或按名字停 ----
nvi-stop() {
    local unit
    if (( $# )); then
        # 显式传名字:允许不带 nvim-server- 前缀
        unit="${1#nvim-server-}"
        unit="nvim-server-${unit%.service}"
    else
        unit=$(_nvi_unit)
    fi

    if ! systemctl --user --quiet is-active "$unit"; then
        echo "not running: $unit" >&2
        # 顺便清一下残留
        systemctl --user reset-failed "$unit" 2>/dev/null
        return 1
    fi
    systemctl --user stop "$unit"
}
alias scu-start-nvim='nvi-server'
# ---- 列出所有在跑的 nvi server ----
nvi-list() {
    systemctl --user list-units --type=service --state=active 'nvim-server-*' --no-pager
}

# ---- fzf 模糊选一个活的 nvim --listen socket,attach 一个 remote UI ----
# 同时认识 nvi-server (nvim-server-*.sock) 和 uri-open.sh (nvim-uri-*.sock)
# 以及任何其它在 $XDG_RUNTIME_DIR 下能响应 --remote-expr 的 *.sock
nvi-attach() {
    emulate -L zsh
    setopt local_options null_glob

    # nvim --remote-expr 只要任一标准流是 tty 就会顺手 init TUI,把终端能力
    # 探测 (CSI ?69$p 等) 写进 stdout 污染结果。三个流全部接 /dev/null/pipe
    # 之后 nvim 走 non-TUI 分支,输出纯净。
    _nvi_probe() { nvim --server "$1" --remote-expr "$2" </dev/null 2>/dev/null; }

    local rt="${XDG_RUNTIME_DIR:-/tmp}"
    local -a entries=()
    local s base unit cwd file bufs

    for s in "$rt"/*.sock; do
        [[ -S "$s" ]] || continue
        cwd=$(_nvi_probe "$s" 'getcwd()') || continue
        [[ -z "$cwd" ]] && continue   # dead socket
        file=$(_nvi_probe "$s" 'expand("%:p")')
        bufs=$(_nvi_probe "$s" 'len(getbufinfo({"buflisted":1}))')
        base="${s:t:r}"
        unit="(adhoc)"
        systemctl --user --quiet is-active "${base}.service" 2>/dev/null && unit="$base"
        entries+=( "${s}"$'\t'"${cwd}  ⟫  ${file:-[no file]}  ⟫  bufs=${bufs}  ⟫  ${unit}" )
    done

    if (( ${#entries[@]} == 0 )); then
        echo "no live nvim sockets under $rt" >&2
        return 1
    fi

    local choice
    choice=$(printf '%s\n' "${entries[@]}" \
        | fzf --delimiter=$'\t' --with-nth=2.. \
              --prompt='attach nvim> ' \
              --header='cwd  ⟫  current file  ⟫  bufs  ⟫  systemd unit') || return 130

    local sock="${choice%%$'\t'*}"
    LANG=C.UTF-8 nvim --server "$sock" --remote-ui
}

jl-run() {
    local unit="junyi-task-julia-${PWD:t}"
    local desc="julia @ ${PWD:t}"
    (( $# )) && desc="${desc} [$*]"

    # 同名 task 已在跑:拒绝启动
    if systemctl --user --quiet is-active "$unit"; then
        echo "already running: $unit" >&2
        echo "  logs: task-logs ${PWD:t}" >&2
        echo "  stop: task-stop" >&2
        return 1
    fi

    # 同 nvi-server: 值为空的 --setenv=NAME 把当前 zsh 的环境搬进 unit。
    # julia 本体在 /usr/bin 不受影响,但脚本 run() 出去的工具 (~/bin、
    # ~/.local/bin、~/.julia/bin) 和已激活的 venv 只存在于 rc 环境里。
    systemd-run --user \
        --unit="$unit" \
        --description="$desc" \
        --working-directory="$PWD" \
        --setenv=PATH \
        --setenv=VIRTUAL_ENV \
        --setenv=CONDA_PREFIX \
        --setenv=JULIA_CONDAPKG_BACKEND \
        --setenv=JULIA_PYTHONCALL_EXE \
        --setenv=JULIA_PKG_OFFLINE \
        --setenv=JULIA_NUM_THREADS \
        --setenv=JULIA_DEPOT_PATH \
        --setenv=JULIA_LOAD_PATH \
	--property="ExecStopPost=/usr/bin/notify-send -a julia \"[${PWD}] result=\${SERVICE_RESULT} exit=\${EXIT_STATUS}\"" \
        julia --project=. "$@"
}

jl-list() {
    systemctl --user list-units --type=service --state=active 'junyi-task-julia-*' --no-pager
}

jl-stop() {
    systemctl --user stop "junyi-task-julia-${PWD:t}"
}

# export NVIM_SERVER="$XDG_RUNTIME_DIR/nvim.main.sock"
