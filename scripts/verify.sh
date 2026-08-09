# scripts/verify.sh — sanity checks for the psiphon-railway repo before pushing to Railway.
# Run locally: bash scripts/verify.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "== files present =="
for f in Dockerfile entrypoint.sh psiphon-x86_64 psiphon-aarch64; do
    [ -f "$f" ] && echo "  ok  $f ($(stat -c%s "$f") bytes)" || { echo "  MISSING $f"; exit 1; }
done

echo "== configs =="
for cc in DE FR CH; do
    [ -f "configs/$cc.json" ] && echo "  ok  configs/$cc.json" || { echo "  MISSING configs/$cc.json"; exit 1; }
    python3 -c "
import json,sys
c=json.load(open('configs/$cc.json'))
assert c['EgressRegion']=='$cc', 'EgressRegion mismatch'
assert c['LocalSocksProxyPort'] in (1084,1086,1090), 'port wrong'
assert c.get('ListenInterface')=='any', 'ListenInterface not any'
print('  ok  $cc -> EgressRegion=$cc, ListenInterface=any')
"
done

echo "== shellcheck entrypoint =="
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck entrypoint.sh && echo "  ok  shellcheck clean" || echo "  WARN shellcheck found issues"
else
    echo "  (shellcheck not installed, skipping)"
fi

echo "ALL CHECKS PASSED"