# omarchy-lsd-theme

Syncs your [lsd](https://github.com/lsd-rs/lsd) colors with your [Omarchy](https://omarchy.org/) system theme automatically.

Every time you run `omarchy theme set`, lsd picks up the same color palette on its next run.

## How it works

Omarchy's template engine processes `lsd.yaml.tpl` using the active theme's `colors.toml`, generating an lsd theme file in `~/.local/state/omarchy/current/theme/lsd.yaml`. A `theme-set` hook copies it to `~/.config/lsd/colors.yaml`, which lsd reads on every invocation (no restart or hot-reload needed).

```
colors.toml ──> omarchy theme set/refresh ──> lsd.yaml (#rrggbb)
                                              ~/.local/state/omarchy/current/theme/
                                                     │
                                               theme-set hook (cp)
                                                     │
                                                     ▼
                                      ~/.config/lsd/colors.yaml
                                      (color.theme: custom)
                                                     │
                                                     ▼
                                          next `lsd` run uses theme ✓
```

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
2. Installs the `theme-set` hook into `~/.config/omarchy/hooks/theme-set.d/`
3. Sets `theme: custom` in `~/.config/lsd/config.yaml` (creates a timestamped backup first)
4. Backs up any pre-existing `colors.yaml` and generates the current theme

It is safe to re-run — the script is idempotent.

The last install step runs `omarchy theme refresh`, which restarts the terminal as part of applying the theme. Save your work first.

## Uninstall

```bash
./uninstall.sh
```

This reverts everything:

1. Removes the template symlink from `~/.config/omarchy/themed/`
2. Removes the hook from `~/.config/omarchy/hooks/theme-set.d/`
3. Restores `theme: default` in `~/.config/lsd/config.yaml`
4. Removes the generated `colors.yaml` and restores any backup

## Test

```bash
./test.sh
```

Smoke test: renders the template with the current theme, asserts lsd loads it (truecolor output, no fallback to the default theme), and checks hook copy/no-op behavior.

## Files

| File             | Purpose                                                        |
| ---------------- | -------------------------------------------------------------- |
| `lsd.yaml.tpl`   | lsd theme template using `{{ key }}` hex placeholders          |
| `theme-set`      | Hook script — copies the generated theme to `colors.yaml`      |
| `install.sh`     | Installer (symlink, hook, config, initial apply)               |
| `uninstall.sh`   | Uninstaller (reverts all changes)                              |
| `test.sh`        | Smoke test                                                     |

## Requirements

- [Omarchy](https://omarchy.org/) Quattro or later with the template/hook system (`omarchy theme set`, `omarchy theme refresh`)
- [lsd](https://github.com/lsd-rs/lsd) 1.2.x with config at `~/.config/lsd/config.yaml`

## Usage

After installing, just use Omarchy as usual:

```bash
omarchy theme set tokyo-night   # lsd uses the new colors on its next run
omarchy theme set catppuccin    # same
```
