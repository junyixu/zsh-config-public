# `~/.config/mimeapps.list` changes for URI handlers

`~/.config/mimeapps.list` is **not** part of this repo (managed by KDE / xdg).
Records what was added by hand after running `install.sh`, so a fresh box can
reproduce the registration.

## Sections touched

Two sections, both need the same line for each scheme:

- `[Added Associations]` — lets the `.desktop` file appear as a candidate
  handler.
- `[Default Applications]` — pins it as the resolved default for
  `xdg-open` / `xdg-mime query default …`.

## Lines added

```ini
[Added Associations]
x-scheme-handler/neovim-note=neovim-note-url-handler.desktop
x-scheme-handler/neovim-typst=neovim-typst-url-handler.desktop

[Default Applications]
x-scheme-handler/neovim-note=neovim-note-url-handler.desktop
x-scheme-handler/neovim-typst=neovim-typst-url-handler.desktop
```

(Earlier iterations used the scheme name `typst`; renamed to
`neovim-typst` to keep all custom nvim-targeting schemes under one
namespace and avoid colliding with any future official `typst://`
scheme.)

## Equivalent commands (preferred over hand-edit)

```sh
xdg-mime default neovim-note-url-handler.desktop  x-scheme-handler/neovim-note
xdg-mime default neovim-typst-url-handler.desktop x-scheme-handler/neovim-typst
```

`xdg-mime default` writes the same `[Default Applications]` lines and is
idempotent. It does **not** populate `[Added Associations]`, but for a
handler that exists in `~/.local/share/applications/` (via `install.sh`
symlink) the default lookup still resolves.

## Verification

```sh
xdg-mime query default x-scheme-handler/neovim-note    # → neovim-note-url-handler.desktop
xdg-mime query default x-scheme-handler/neovim-typst   # → neovim-typst-url-handler.desktop

xdg-open 'neovim-note:///etc/hosts#L3'
xdg-open 'neovim-typst:///tmp/test.typ#L5'
```

## When the scheme was renamed

If an older registration of `x-scheme-handler/typst=typst-url-handler.desktop`
is still present, drop both `[Added Associations]` and `[Default Applications]`
lines for it, then `rm ~/.local/share/applications/typst-url-handler.desktop`
(the stale symlink left behind by the previous `install.sh` run) and
`update-desktop-database ~/.local/share/applications`.
