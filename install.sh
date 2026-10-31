#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMED_DIR="$HOME/.config/omarchy/themed"
HOOKS_DIR="$HOME/.config/omarchy/hooks"
LSD_DIR="$HOME/.config/lsd"
LSD_CONFIG="$LSD_DIR/config.yaml"
LSD_COLORS_FILE="$LSD_DIR/colors.yaml"

echo "=== omarchy-lsd-theme installer ==="

# 1. Symlink template
mkdir -p "$THEMED_DIR"
if [[ -L "$THEMED_DIR/lsd.yaml.tpl" ]]; then
  echo "[1/4] Template symlink already exists, updating..."
  rm "$THEMED_DIR/lsd.yaml.tpl"
fi
ln -s "$SCRIPT_DIR/lsd.yaml.tpl" "$THEMED_DIR/lsd.yaml.tpl"
echo "[1/4] Symlinked template -> $THEMED_DIR/lsd.yaml.tpl"

# 2. Install hook
mkdir -p "$HOOKS_DIR/theme-set.d"
HOOK_TARGET="$HOOKS_DIR/theme-set.d/omarchy-lsd-theme"
if [[ -L "$HOOK_TARGET" || -f "$HOOK_TARGET" ]]; then
  rm "$HOOK_TARGET"
fi
ln -s "$SCRIPT_DIR/theme-set" "$HOOK_TARGET"
echo "[2/4] Installed hook -> $HOOK_TARGET"

# 3. Configure lsd to use the generated colors.yaml
mkdir -p "$LSD_DIR"
if [[ -f "$LSD_CONFIG" ]] && grep -qE '^[[:space:]]*theme:[[:space:]]*custom[[:space:]]*$' "$LSD_CONFIG"; then
  echo "[3/4] lsd config already has theme: custom, skipping."
else
  if [[ -f "$LSD_CONFIG" ]]; then
    cp "$LSD_CONFIG" "$LSD_CONFIG.bak.$(date +%s)"
    if grep -qE '^[[:space:]]*theme:' "$LSD_CONFIG"; then
      sed -i -E 's|^([[:space:]]*theme:).*|\1 custom|' "$LSD_CONFIG"
    elif grep -qE '^color:' "$LSD_CONFIG"; then
      sed -i '/^color:/a\  theme: custom' "$LSD_CONFIG"
    else
      printf '\ncolor:\n  theme: custom\n' >> "$LSD_CONFIG"
    fi
    echo "[3/4] Set theme: custom in lsd config (backup created)."
  else
    printf 'color:\n  when: auto\n  theme: custom\n' > "$LSD_CONFIG"
    echo "[3/4] Created lsd config with theme: custom."
  fi
fi

# 4. Back up any pre-existing colors.yaml and apply the current theme
if [[ -f "$LSD_COLORS_FILE" ]]; then
  cp "$LSD_COLORS_FILE" "$LSD_COLORS_FILE.bak.$(date +%s)"
  echo "[4/4] Backed up existing colors.yaml."
fi

CURRENT_THEME=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || echo "")
if [[ -n "$CURRENT_THEME" ]]; then
  echo "[4/4] Applying current theme '$CURRENT_THEME' to lsd..."
  omarchy theme refresh
  echo "[4/4] Done! colors.yaml generated (picked up by lsd on next run)."
else
  echo "[4/4] No current theme found. Theme will sync on next omarchy theme set."
fi

echo ""
echo "=== Installation complete ==="
echo "To revert, run: $SCRIPT_DIR/uninstall.sh"
