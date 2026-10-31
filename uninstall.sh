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
  echo "[1/4] Removed template symlink."
else
  echo "[1/4] Template symlink not found, skipping."
fi

# 2. Remove legacy copy hook (older versions)
if [[ -L "$HOOKS_DIR/theme-set.d/omarchy-lsd-theme" || -f "$HOOKS_DIR/theme-set.d/omarchy-lsd-theme" ]]; then
  rm "$HOOKS_DIR/theme-set.d/omarchy-lsd-theme"
  echo "[2/4] Removed legacy theme-set hook."
else
  echo "[2/4] No theme-set hook found, skipping."
fi

# 3. Restore lsd config
if [[ -f "$LSD_CONFIG" ]] && grep -qE '^[[:space:]]*theme:[[:space:]]*custom[[:space:]]*$' "$LSD_CONFIG"; then
  sed -i -E 's|^([[:space:]]*theme:)[[:space:]]*custom[[:space:]]*$|\1 default|' "$LSD_CONFIG"
  echo "[3/4] Restored theme: default in lsd config."
else
  echo "[3/4] theme: custom not set in lsd config, skipping."
fi

# 4. Remove colors.yaml (symlink or generated file) and restore any backup
if [[ -e "$LSD_COLORS_FILE" || -L "$LSD_COLORS_FILE" ]]; then
  rm "$LSD_COLORS_FILE"
  echo "[4/4] Removed colors.yaml."
else
  echo "[4/4] colors.yaml not found, skipping."
fi

LATEST_BACKUP=$(ls -t "$LSD_DIR"/colors.yaml.bak.* 2>/dev/null | head -1 || true)
if [[ -n "$LATEST_BACKUP" ]]; then
  mv "$LATEST_BACKUP" "$LSD_COLORS_FILE"
  echo "      Restored colors.yaml from backup."
fi

echo ""
echo "=== Uninstall complete ==="
