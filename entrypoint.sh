#!/bin/bash
# psiphon-railway entrypoint
# Starts one psiphon tunnel-core instance per region listed in $REGIONS.
# Each instance binds its SOCKS5 proxy on 0.0.0.0:<port> (ListenInterface=any)
# so Railway TCP Proxy can forward external traffic to it.
#
# Regions are ISO 3166-1 alpha-2 codes with a matching configs/<CC>.json file.
# On Railway, map one TCP Proxy per region (internal port = region's port).

set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-/etc/psiphon/configs}"
REGIONS="${REGIONS:-DE FR CH}"

log() { echo "[entrypoint] $*"; }

start_region() {
    local cc="$1"
    local cfg="$CONFIG_DIR/${cc}.json"
    if [ ! -f "$cfg" ]; then
        echo "[entrypoint] WARNING: no config for $cc (expected $cfg), skipping" >&2
        return
    fi
    log "starting region $cc with $cfg"
    # run in background so multiple regions coexist in one container
    /usr/local/bin/psiphon -config "$cfg" &
}

log "starting psiphon regions: $REGIONS"
for cc in $REGIONS; do
    start_region "$cc"
done

# Keep the container alive. The psiphon children keep running in the
# background; if they all die we stay up (Railway healthcheck will see it).
log "all regions spawned — container now stays alive"
while true; do
    sleep 30
done