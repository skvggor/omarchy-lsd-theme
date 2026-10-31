# omarchy-lsd-theme

Syncs your [lsd](https://github.com/lsd-rs/lsd) colors with your [Omarchy](https://omarchy.org/) theme.

Each `omarchy theme set` is available to lsd on its next run, from the moment the theme state updates (before the theme-set restarts finish).

## How it works

Omarchy's template engine processes `lsd.yaml.tpl` against the active theme's `colors.toml` and writes `~/.local/state/omarchy/current/theme/lsd.yaml`. The installer points `~/.config/lsd/colors.yaml` at that file with a symlink. lsd reads the current theme on each run; there is no copy step and no hook.

```
colors.toml ──> omarchy theme set/refresh ──> lsd.yaml (#rrggbb)
                                              ~/.local/state/omarchy/current/theme/
                                                     ▲
                          ~/.config/lsd/colors.yaml ─┘  (symlink, created at install)
                          (color.theme: custom)
                                                     │
                                                     ▼
                                           next `lsd` run uses theme ✓
```

The symlink resolves to the new file as soon as the theme state swaps (before terminal/shell restarts complete). Output already printed to the scrollback keeps its colors: it is static text, like any CLI output. A TUI such as Zellij re-renders itself; lsd does not.

### Color mapping

| lsd element             | Omarchy color           |
| ----------------------- | ----------------------- |
| `user`                  | `accent`                |
| `group`                 | `muted`                 |
| permission read/write/exec/sticky | `green` / `yellow` / `red` / `magenta` |
| date hour/day/older     | `green` / `yellow` / `muted`            |
| size small/medium/large | `green` / `yellow` / `red`              |
| inode/links valid       | `cyan`                  |
| git new/renamed, modified, deleted | `green` / `yellow` / `red` |
| edges, invalid, muted   | `muted`                 |

File/directory name colors are not part of lsd's color theme in 1.2.x. They come from `LS_COLORS` and follow your terminal palette.

## Install

```bash
git clone https://github.com/skvggor/omarchy-lsd-theme.git
cd omarchy-lsd-theme
./install.sh
```

The installer:

1. Symlinks `lsd.yaml.tpl` into `~/.config/omarchy/themed/`
2. Removes the legacy copy hook from the old version (if present)
3. Sets `theme: custom` in `~/.config/lsd/config.yaml` (creates a timestamped backup first)
4. Replaces `colors.yaml` with a symlink to the generated theme (backs up a regular file first)
5. Generates the current theme

The script is idempotent; re-running it is safe.

The last step runs `omarchy theme refresh`, which restarts the terminal. Save your work first.

## Uninstall

```bash
./uninstall.sh
```

1. Removes the template symlink from `~/.config/omarchy/themed/`
2. Removes any legacy hook
3. Restores `theme: default` in `~/.config/lsd/config.yaml`
4. Removes `colors.yaml` and restores any backup

## Test

```bash
./test.sh
```

Renders the template with the current theme, checks that lsd loads it (truecolor output, no fallback to the default theme), checks that the symlinked `colors.yaml` follows state file changes, and checks that lsd exits 0 while the theme target is missing during a swap.

## Files

| File             | Purpose                                                        |
| ---------------- | -------------------------------------------------------------- |
| `lsd.yaml.tpl`   | lsd theme template using `{{ key }}` hex placeholders          |
| `install.sh`     | Installer (template symlink, config, colors.yaml symlink)      |
| `uninstall.sh`   | Uninstaller (reverts all changes)                              |
| `test.sh`        | Test script                                                    |

## Requirements

- [Omarchy](https://omarchy.org/) Quattro or later with the template system (`omarchy theme set`, `omarchy theme refresh`)
- [lsd](https://github.com/lsd-rs/lsd) 1.2.x with config at `~/.config/lsd/config.yaml`

## Usage

```bash
omarchy theme set tokyo-night   # lsd uses the new colors on its next run
omarchy theme set catppuccin    # same
```
