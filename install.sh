#! /usr/bin/sh
# vim:fenc=utf-8

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
echo 'for f in ~/.config/zsh/zshrc.d/*.zsh(N); do source "$f"; done && typeset -U path PATH' >> ~/.zshrc

# Symlink scripts → ~/.local/bin, .desktop URI handlers → ~/.local/share/applications
for src in "$SRC_DIR/bin/"*; do
    [ -e "$src" ] || continue
    ln -sfv "$src" "$HOME/.local/bin/$(basename "$src")"
done
for src in "$SRC_DIR/share/applications/"*.desktop; do
    [ -e "$src" ] || continue
    ln -sfv "$src" "$HOME/.local/share/applications/$(basename "$src")"
done
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
