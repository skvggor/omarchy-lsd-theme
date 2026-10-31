#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

FAILED=0

pass() {
  echo "ok - $1"
}

fail() {
  echo "fail - $1"
  FAILED=1
}

# Render the template exactly like omarchy-theme-set-templates does,
# but against the current theme colors.
SED_SCRIPT="$WORK_DIR/sed"
: > "$SED_SCRIPT"
while IFS=$'\t' read -r key value; do
  printf 's|{{ %s }}|%s|g\n' "$key" "$value" >> "$SED_SCRIPT"
done < <(omarchy-theme-color --all)
sed -f "$SED_SCRIPT" "$SCRIPT_DIR/lsd.yaml.tpl" > "$WORK_DIR/colors.yaml"

# 1. No unresolved placeholders remain
if grep -q '{{' "$WORK_DIR/colors.yaml"; then
  fail "rendered theme has unresolved placeholders"
else
  pass "template rendered without leftover placeholders"
fi

# 2. lsd accepts the theme (truecolor escapes prove the custom theme loaded;
#    the default theme only emits 256-color escapes)
cat > "$WORK_DIR/config.yaml" <<EOF
color:
  when: always
  theme: $WORK_DIR/colors.yaml
EOF
OUTPUT=$(lsd --config-file "$WORK_DIR/config.yaml" -l --color always "$WORK_DIR/colors.yaml" 2>&1) || fail "lsd exited nonzero"
if printf '%s' "$OUTPUT" | grep -q '38;2;'; then
  pass "lsd applies the generated theme (truecolor escapes present)"
else
  fail "lsd fell back to the default theme"
fi

# 3. Hook is a no-op when the generated theme is missing
FAKE_HOME="$WORK_DIR/fake-home"
mkdir -p "$FAKE_HOME"
if HOME="$FAKE_HOME" "$SCRIPT_DIR/theme-set"; then
  pass "hook exits 0 when theme state is missing"
else
  fail "hook failed when theme state is missing"
fi

# 4. Hook copies the generated theme into place
mkdir -p "$FAKE_HOME/.local/state/omarchy/current/theme" "$FAKE_HOME/.config/lsd"
cp "$WORK_DIR/colors.yaml" "$FAKE_HOME/.local/state/omarchy/current/theme/lsd.yaml"
if HOME="$FAKE_HOME" "$SCRIPT_DIR/theme-set" && cmp -s "$WORK_DIR/colors.yaml" "$FAKE_HOME/.config/lsd/colors.yaml"; then
  pass "hook copies generated theme to ~/.config/lsd/colors.yaml"
else
  fail "hook did not copy the generated theme"
fi

exit "$FAILED"
