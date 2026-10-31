#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMED_DIR="$HOME/.config/omarchy/themed"
HOOKS_DIR="$HOME/.config/omarchy/hooks"
LSD_DIR="$HOME/.config/lsd"
LSD_CONFIG="$LSD_DIR/config.yaml"
LSD_COLORS_FILE="$LSD_DIR/colors.yaml"
GENERATED_THEME="$HOME/.local/state/omarchy/current/theme/lsd.yaml"

echo "=== omarchy-lsd-theme installer ==="

# 1. Symlink template
mkdir -p "$THEMED_DIR"
if [[ -L "$THEMED_DIR/lsd.yaml.tpl" ]]; then
  echo "[1/5] Template symlink already exists, updating..."
  rm "$THEMED_DIR/lsd.yaml.tpl"
fi
ln -s "$SCRIPT_DIR/lsd.yaml.tpl" "$THEMED_DIR/lsd.yaml.tpl"
echo "[1/5] Symlinked template -> $THEMED_DIR/lsd.yaml.tpl"

# 2. Remove legacy hook from the copy-based version
HOOK_TARGET="$HOOKS_DIR/theme-set.d/omarchy-lsd-theme"
if [[ -L "$HOOK_TARGET" || -f "$HOOK_TARGET" ]]; then
  rm "$HOOK_TARGET"
  echo "[2/5] Removed legacy copy hook (now a direct symlink, no hook needed)."
else
  echo "[2/5] No legacy hook found, skipping."
fi

# 3. Configure lsd to use the generated colors.yaml
mkdir -p "$LSD_DIR"
if [[ -f "$LSD_CONFIG" ]] && grep -qE '^[[:space:]]*theme:[[:space:]]*custom[[:space:]]*$' "$LSD_CONFIG"; then
  echo "[3/5] lsd config already has theme: custom, skipping."
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
    echo "[3/5] Set theme: custom in lsd config (backup created)."
  else
    printf 'color:\n  when: auto\n  theme: custom\n' > "$LSD_CONFIG"
    echo "[3/5] Created lsd config with theme: custom."
  fi
fi

# 4. Point colors.yaml at the generated theme (updates at staging time,
#    before theme-set restarts — no hook needed)
if [[ -L "$LSD_COLORS_FILE" ]]; then
  ln -sfn "$GENERATED_THEME" "$LSD_COLORS_FILE"
  echo "[4/5] Updated colors.yaml symlink -> $GENERATED_THEME"
elif [[ -f "$LSD_COLORS_FILE" ]]; then
  mv "$LSD_COLORS_FILE" "$LSD_COLORS_FILE.bak.$(date +%s)"
  ln -sfn "$GENERATED_THEME" "$LSD_COLORS_FILE"
  echo "[4/5] Replaced regular colors.yaml with symlink (backup created)."
else
  ln -sfn "$GENERATED_THEME" "$LSD_COLORS_FILE"
  echo "[4/5] Created colors.yaml symlink -> $GENERATED_THEME"
fi

# 5. Generate the current theme so the symlink resolves
CURRENT_THEME=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || echo "")
if [[ -n "$CURRENT_THEME" ]]; then
  echo "[5/5] Applying current theme '$CURRENT_THEME'..."
  omarchy theme refresh
  echo "[5/5] Done! lsd follows ~/.local/state/omarchy/current/theme/lsd.yaml live."
else
  echo "[5/5] No current theme found. Symlink activates on next omarchy theme set."
fi

echo ""
echo "=== Installation complete ==="
echo "To revert, run: $SCRIPT_DIR/uninstall.sh"
