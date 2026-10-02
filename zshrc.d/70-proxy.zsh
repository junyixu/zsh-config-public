# 代理管理策略:
# - environment.d/73-proxy.conf 在系统启动时设置全局代理，供系统服务使用
# - shell 中默认禁用代理，避免影响终端命令的直连性能
# - 需要时可使用下方的函数临时启用代理
# export ALL_PROXY=
# export HTTP_PROXY=
# export HTTPS_PROXY=

# 代理管理函数
proxy_on() {
    export ALL_PROXY="http://localhost:20172"
    export HTTP_PROXY="http://localhost:20172"
    export HTTPS_PROXY="http://localhost:20172"
    export GIT_SOCKS_PROXY="socks5://localhost:20171"
    echo "✓ Proxy enabled (http://localhost:20172)"
}

proxy_off() {
    unset ALL_PROXY HTTP_PROXY HTTPS_PROXY GIT_SOCKS_PROXY
    echo "✓ Proxy disabled"
}

proxy_status() {
    if [[ -n "$ALL_PROXY" ]]; then
        echo "Proxy: ON ($ALL_PROXY)"
    else
        echo "Proxy: OFF"
    fi
    echo "ALL_PROXY: ${ALL_PROXY:-unset}"
    echo "HTTP_PROXY: ${HTTP_PROXY:-unset}"
    echo "HTTPS_PROXY: ${HTTPS_PROXY:-unset}"
    echo "GIT_SOCKS_PROXY: ${GIT_SOCKS_PROXY:-unset}"
}

# socks5 代理 (curl, git, pacman, yay 可以设置 all_proxy 变量直接使用）
# export all_proxy="socks5://127.0.0.1:1080"
# 笔记： 这是 python requests 包里的语法格式，对 shell 没用，多了个h 的意思是域名也送给代理解析，本地不解析域名
#export all_proxy="socks5h://127.0.0.1:1080"
# export all_proxy="http://127.0.0.1:1081"
# export JUPYTERLAB_DIR=$HOME/.local/share/jupyter/lab
