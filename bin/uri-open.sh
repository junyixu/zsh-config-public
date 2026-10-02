#!/usr/bin/env bash
# Custom URI handler: neovim-note://, neovim-typst://
# Form: <scheme>:///abs/path/file.ext[#L<line>]
#
# Architecture (mirrors ~/.config/zsh/zshrc.d/50-systemd-run.zsh nvi-server):
# - headless nvim per project, managed by `systemd-run --user --unit=...`
#   (so the process survives the handler exit and is inspectable via journalctl)
# - kitty tab attaches via `nvim --server $sock --remote-ui`
# - subsequent links reuse both the nvim unit and the kitty tab
set -euo pipefail

uri="${1:?usage: uri-open.sh <uri>}"
log="${XDG_RUNTIME_DIR:-/tmp}/uri-open.log"
exec >>"$log" 2>&1
echo "[$(date -Iseconds)] uri=$uri"

scheme="${uri%%://*}"
rest="${uri#*://}"
case "$scheme" in
    neovim-note|neovim-typst) ;;
    *) echo "unsupported scheme: $scheme" >&2; exit 2 ;;
esac

if [[ "$rest" == *"#"* ]]; then
    raw_path="${rest%%#*}"
    frag="${rest#*#}"
else
    raw_path="$rest"
    frag=""
fi
raw_path="${raw_path%%\?*}"

urldecode() {
    local s="${1//+/ }"
    printf '%b' "${s//%/\\x}"
}
path="$(urldecode "$raw_path")"
[[ "$path" == /* ]] || { echo "path must be absolute: $path" >&2; exit 3; }

line=1
[[ "$frag" =~ ^L([0-9]+)$ ]] && line="${BASH_REMATCH[1]}"

dir="$(dirname "$path")"
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")"

# Socket + systemd unit name — same conventions as nvi-server in the zsh helper
base="${root##*/}"; [[ -z "$base" ]] && base="root"
hash="$(printf '%s' "$root" | cksum | awk '{print $1}')"
unit="nvim-uri-${scheme}-$(systemd-escape "$base")-${hash}"
sock="${XDG_RUNTIME_DIR:-/tmp}/${unit}.sock"
lock="${sock}.lock"
tab_title="${scheme}: ${base}"

socket_alive() {
    [[ -S "$sock" ]] && nvim --server "$sock" --remote-expr '1' >/dev/null 2>&1
}

unit_active() {
    systemctl --user --quiet is-active "$unit"
}

find_kitty_sock() {
    if [[ -n "${KITTY_LISTEN_ON:-}" ]]; then
        printf '%s' "$KITTY_LISTEN_ON"; return
    fi
    local s
    for s in /tmp/kitty-*; do
        [[ -S "$s" ]] || continue
        if kitty @ --to "unix:$s" ls >/dev/null 2>&1; then
            printf '%s' "unix:$s"; return
        fi
    done
    return 1
}

KITTY_SOCK=""
ensure_kitty() {
    KITTY_SOCK="$(find_kitty_sock || true)"
    [[ -n "$KITTY_SOCK" ]] && return
    echo "spawn kitty (no remote socket responding)"
    setsid -f kitty >/dev/null 2>&1
    for _ in {1..40}; do
        KITTY_SOCK="$(find_kitty_sock || true)"
        [[ -n "$KITTY_SOCK" ]] && return
        sleep 0.1
    done
    echo "kitty failed to come up" >&2
    return 1
}

start_nvim_unit() {
    # Clean up any stale failed unit + dangling socket
    systemctl --user reset-failed "$unit" 2>/dev/null || true
    [[ -e "$sock" ]] && rm -f "$sock"
    echo "systemd-run nvim unit=$unit sock=$sock"
    systemd-run --user \
        --unit="$unit" \
        --working-directory="$root" \
        --setenv=LANG=en_US.UTF-8 \
        --description="uri-handler nvim (${scheme}) @ ${root}" \
        nvim --headless --listen "$sock"
    for _ in {1..50}; do
        socket_alive && return 0
        sleep 0.1
    done
    echo "nvim socket never came up for unit=$unit" >&2
    return 1
}

ensure_kitty_tab() {
    # Returns 0 if a tab attached to $sock already exists in any kitty OS
    # window; otherwise spawns a new tab that attaches via --remote-ui.
    if kitty @ --to "$KITTY_SOCK" focus-tab --match "title:^${tab_title}$" >/dev/null 2>&1; then
        echo "reuse kitty tab title='${tab_title}'"
        return 0
    fi
    echo "kitty @ launch --type=tab title='${tab_title}'"
    kitty @ --to "$KITTY_SOCK" launch \
        --type=tab \
        --cwd="$root" \
        --title="$tab_title" \
        --var="uri_scheme=${scheme}" \
        nvim --server "$sock" --remote-ui >/dev/null
}

nvim_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/ /\\ /g' -e 's/%/\\%/g' -e 's/#/\\#/g' -e 's/|/\\|/g'; }
esc_path="$(nvim_escape "$path")"
remote_cmd=$'<C-\\><C-N>:edit +'"${line} ${esc_path}"$'<CR>'
if [[ "$scheme" == "neovim-typst" ]]; then
    # Idempotent: only start TypstPreview the first time this buffer is touched
    # in the current nvim instance, so re-clicking the URL won't spawn another
    # preview server / browser tab.
    remote_cmd+=':lua if not vim.b.uri_typst_started then vim.cmd("TypstPreview") vim.b.uri_typst_started = true end<CR>'
fi

(
    flock 9
    ensure_kitty
    if ! socket_alive; then
        if unit_active; then
            echo "unit active but socket dead — restarting unit=$unit"
            systemctl --user stop "$unit" 2>/dev/null || true
        fi
        start_nvim_unit
    fi
    ensure_kitty_tab
    nvim --server "$sock" --remote-send "$remote_cmd"
) 9>"$lock"

ww -f kitty >/dev/null 2>&1 || true
