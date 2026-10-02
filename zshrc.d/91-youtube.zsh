# 远程YouTube下载别名
yt-remote() {
    if [ -z "$1" ]; then
        echo "使用方法: yt-remote [YouTube视频URL]"
        return 1
    fi

    local video_url="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local logfile="/tmp/yt_download_${timestamp}.log"

    echo "开始在debian12上下载: $video_url"
    echo "日志文件: $logfile"

    ssh junyi@debian12 "nohup yt-dlp '$video_url' > $logfile 2>&1 &"
    echo "下载任务已在后台启动"
}

alias ytdl='yt-remote'

