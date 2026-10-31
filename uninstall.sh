#!/bin/bash

set -euo pipefail

THEMED_DIR="$HOME/.config/omarchy/themed"
HOOKS_DIR="$HOME/.config/omarchy/hooks"
LSD_DIR="$HOME/.config/lsd"
LSD_CONFIG="$LSD_DIR/config.yaml"
LSD_COLORS_FILE="$LSD_DIR/colors.yaml"

echo "=== omarchy-lsd-theme uninstaller ==="

# 1. Remove template symlink
if [[ -L "$THEMED_DIR/lsd.yaml.tpl" ]]; then
  rm "$THEMED_DIR/lsd.yaml.tpl"
  echo "[1/3] Removed template symlink."
else
  echo "[1/3] Template symlink not found, skipping."
fi

# 2. Remove hook
if [[ -L "$HOOKS_DIR/theme-set.d/omarchy-lsd-theme" || -f "$HOOKS_DIR/theme-set.d/omarchy-lsd-theme" ]]; then
  rm "$HOOKS_DIR/theme-set.d/omarchy-lsd-theme"
  echo "[2/3] Removed theme-set.d hook."
else
  echo "[2/3] No theme-set hook found, skipping."
fi

# 3. Restore lsd config and colors.yaml
if [[ -f "$LSD_CONFIG" ]] && grep -qE '^[[:space:]]*theme:[[:space:]]*custom[[:space:]]*$' "$LSD_CONFIG"; then
  sed -i -E 's|^([[:space:]]*theme:)[[:space:]]*custom[[:space:]]*$|\1 default|' "$LSD_CONFIG"
  echo "[3/3] Restored theme: default in lsd config."
else
  echo "[3/3] theme: custom not set in lsd config, skipping."
fi

if [[ -f "$LSD_COLORS_FILE" ]]; then
  rm "$LSD_COLORS_FILE"
  echo "      Removed generated colors.yaml."
fi

LATEST_BACKUP=$(ls -t "$LSD_DIR"/colors.yaml.bak.* 2>/dev/null | head -1 || true)
if [[ -n "$LATEST_BACKUP" ]]; then
  mv "$LATEST_BACKUP" "$LSD_COLORS_FILE"
  echo "      Restored colors.yaml from backup."
fi

echo ""
echo "=== Uninstall complete ==="
