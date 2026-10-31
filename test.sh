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

# Set up a fake home mirroring the installed layout: colors.yaml is a
# symlink to the generated theme inside the omarchy state directory.
FAKE_HOME="$WORK_DIR/fake-home"
FAKE_STATE="$FAKE_HOME/.local/state/omarchy/current/theme"
FAKE_LSD="$FAKE_HOME/.config/lsd"
mkdir -p "$FAKE_STATE" "$FAKE_LSD"
cat > "$FAKE_LSD/config.yaml" <<EOF
color:
  when: always
  theme: custom
EOF
cp "$WORK_DIR/colors.yaml" "$FAKE_STATE/lsd.yaml"
ln -s "$FAKE_STATE/lsd.yaml" "$FAKE_LSD/colors.yaml"

# 3. Live update: changing the state file alone (as a theme set swap does)
#    must change what the next lsd invocation renders — no copy step.
printf 'user: "#ff0000"\n' > "$FAKE_STATE/lsd.yaml"
OUTPUT=$(HOME="$FAKE_HOME" lsd -l --color always "$WORK_DIR/colors.yaml" 2>&1) || fail "lsd exited nonzero (red)"
if printf '%s' "$OUTPUT" | grep -q '38;2;255;0;0'; then
  pass "symlinked colors.yaml reflects state file changes live"
else
  fail "lsd did not pick up the updated state file"
fi

printf 'user: "#00ff00"\n' > "$FAKE_STATE/lsd.yaml"
OUTPUT=$(HOME="$FAKE_HOME" lsd -l --color always "$WORK_DIR/colors.yaml" 2>&1) || fail "lsd exited nonzero (green)"
if printf '%s' "$OUTPUT" | grep -q '38;2;0;255;0'; then
  pass "next invocation picks up the newest theme without any hook"
else
  fail "lsd did not pick up the second state file change"
fi

# 4. Edge: during the theme swap the target is briefly missing — lsd must
#    degrade gracefully (exit 0) instead of erroring.
rm "$FAKE_STATE/lsd.yaml"
if HOME="$FAKE_HOME" lsd -1 --color always "$WORK_DIR/colors.yaml" >/dev/null 2>&1; then
  pass "lsd exits 0 while the theme target is momentarily missing"
else
  fail "lsd errored on a dangling colors.yaml symlink"
fi

exit "$FAILED"
