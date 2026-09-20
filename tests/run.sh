#!/usr/bin/env bash
# Self-contained test suite: a stub `aerospace` on PATH and a throwaway toml,
# so nothing here touches the real config or a running AeroSpace.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GAPS="$ROOT/bin/aerospace-gaps"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

export XDG_CONFIG_HOME="$TMP/xdg"   # keep a real user config out of the run
export AEROSPACE_CONFIG="$TMP/aerospace.toml"
export AEROSPACE_GAPS_NO_RELOAD=1
export PATH="$TMP/stub:$PATH"
mkdir -p "$TMP/stub" "$XDG_CONFIG_HOME"

# Stub CLI: prints whatever monitor names MONITORS holds, one per line.
cat > "$TMP/stub/aerospace" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  list-monitors) printf '%s\n' "${MONITORS:-Built-in Retina Display}" ;;
  reload-config) echo "stub: reloaded" ;;
esac
STUB
chmod +x "$TMP/stub/aerospace"

pass=0 fail=0
ok()   { printf '  ok   %s\n' "$1"; pass=$((pass+1)); }
bad()  { printf '  FAIL %s\n     %s\n' "$1" "$2"; fail=$((fail+1)); }
check(){ [[ $2 == "$3" ]] && ok "$1" || bad "$1" "expected '$3', got '$2'"; }

fixture() {
  cat > "$AEROSPACE_CONFIG" <<TOML
[gaps]
inner.horizontal = 12
outer.left =       12
outer.top    = ${1:-10}
#outer.top =         [{ monitor.secondary = 40 }, 10]
outer.right =      8
TOML
}
top() { sed -n 's/^[[:space:]]*outer\.top[[:space:]]*=[[:space:]]*\([0-9]\{1,\}\).*/\1/p' "$AEROSPACE_CONFIG" | head -n1; }

echo "aerospace-gaps tests"

fixture 10; "$GAPS" docked >/dev/null
check "docked sets the docked value" "$(top)" "40"

fixture 40; "$GAPS" native >/dev/null
check "native sets the native value" "$(top)" "10"

fixture 10; "$GAPS" toggle >/dev/null
check "toggle native -> docked" "$(top)" "40"

fixture 40; "$GAPS" toggle >/dev/null
check "toggle docked -> native" "$(top)" "10"

fixture 10; out=$("$GAPS" native)
check "no-op is reported, not rewritten" "$out" "outer.top already 10 — nothing to do"

fixture 10; MONITORS="LG ULTRAGEAR" "$GAPS" auto >/dev/null
check "external monitor detects as docked" "$(top)" "40"

fixture 40; MONITORS="Built-in Retina Display" "$GAPS" auto >/dev/null
check "built-in display detects as native" "$(top)" "10"

fixture 10; MONITORS=$'Built-in Retina Display\nDELL U2720Q' "$GAPS" auto >/dev/null
check "one external among several is docked" "$(top)" "40"

fixture 10; MONITORS="DELL U2720Q" AEROSPACE_DOCKED_MONITOR="ultragear" "$GAPS" auto >/dev/null
check "explicit regex overrides built-in heuristic" "$(top)" "10"

fixture 40; grep -q '^#outer.top' "$AEROSPACE_CONFIG" && "$GAPS" native >/dev/null
check "commented-out gap line is untouched" \
  "$(grep -c '^#outer.top =         \[{ monitor.secondary = 40 }, 10\]' "$AEROSPACE_CONFIG")" "1"

fixture 10; chmod 0644 "$AEROSPACE_CONFIG"; "$GAPS" docked >/dev/null
check "file permissions survive a rewrite" "$(stat -f '%Lp' "$AEROSPACE_CONFIG" 2>/dev/null || stat -c '%a' "$AEROSPACE_CONFIG")" "644"

fixture 10
mkdir -p "$XDG_CONFIG_HOME/aerospace-gaps"
echo 'AEROSPACE_GAP_DOCKED=32' > "$XDG_CONFIG_HOME/aerospace-gaps/config"
"$GAPS" docked >/dev/null
check "config file supplies defaults" "$(top)" "32"
rm -f "$XDG_CONFIG_HOME/aerospace-gaps/config"

fixture 10; "$GAPS" bogus >/dev/null 2>&1
check "unknown command exits non-zero" "$?" "1"

rm -f "$AEROSPACE_CONFIG"; "$GAPS" status >/dev/null 2>&1
check "missing config exits non-zero" "$?" "1"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
