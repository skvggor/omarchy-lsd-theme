# omarchy-lsd-theme

Syncs your [lsd](https://github.com/lsd-rs/lsd) colors with your [Omarchy](https://omarchy.org/) system theme automatically.

Every time you run `omarchy theme set`, lsd picks up the same color palette on its next run — as soon as the theme state updates, even before the theme-set restarts finish.

## How it works

Omarchy's template engine processes `lsd.yaml.tpl` using the active theme's `colors.toml`, generating an lsd theme file in `~/.local/state/omarchy/current/theme/lsd.yaml`. The installer points `~/.config/lsd/colors.yaml` at that file with a symlink, so lsd always reads the current theme — there is no copy step and no hook to run.

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

Because lsd reads the theme on every invocation, each `omarchy theme set` is reflected instantly — the symlink resolves to the new file the moment the theme state swaps (before terminal/shell restarts complete). Already-printed output in your scrollback is static text and keeps its colors; that is inherent to any CLI tool (unlike a TUI such as Zellij, which re-renders itself).

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

File/directory name colors are not part of lsd's color theme in 1.2.x — they come from `LS_COLORS` and follow your terminal palette.

## Install

```bash
git clone https://github.com/skvggor/omarchy-lsd-theme.git
cd omarchy-lsd-theme
./install.sh
```

The installer:

1. Symlinks `lsd.yaml.tpl` into `~/.config/omarchy/themed/`
2. Removes the legacy copy hook from the old hook-based version (if present)
3. Sets `theme: custom` in `~/.config/lsd/config.yaml` (creates a timestamped backup first)
4. Replaces `colors.yaml` with a symlink to the generated theme (backs up a regular file first)
5. Generates the current theme

It is safe to re-run — the script is idempotent.

The last install step runs `omarchy theme refresh`, which restarts the terminal as part of applying the theme. Save your work first.

## Uninstall

```bash
./uninstall.sh
```

This reverts everything:

1. Removes the template symlink from `~/.config/omarchy/themed/`
2. Removes any legacy hook from the old version
3. Restores `theme: default` in `~/.config/lsd/config.yaml`
4. Removes `colors.yaml` and restores any backup

## Test

```bash
./test.sh
```

Smoke test: renders the template with the current theme, asserts lsd loads it (truecolor output, no fallback to the default theme), verifies the symlinked `colors.yaml` follows state file changes live, and checks graceful degradation while the theme target is momentarily missing during a swap.

## Files

| File             | Purpose                                                        |
| ---------------- | -------------------------------------------------------------- |
| `lsd.yaml.tpl`   | lsd theme template using `{{ key }}` hex placeholders          |
| `install.sh`     | Installer (template symlink, config, colors.yaml symlink)      |
| `uninstall.sh`   | Uninstaller (reverts all changes)                              |
| `test.sh`        | Smoke test                                                     |

## Requirements

- [Omarchy](https://omarchy.org/) Quattro or later with the template system (`omarchy theme set`, `omarchy theme refresh`)
- [lsd](https://github.com/lsd-rs/lsd) 1.2.x with config at `~/.config/lsd/config.yaml`

## Usage

After installing, just use Omarchy as usual:

```bash
omarchy theme set tokyo-night   # lsd uses the new colors on its next run
omarchy theme set catppuccin    # same
```
