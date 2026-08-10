# Psiphon multi-region client for Railway
# Runs one psiphon tunnel-core instance per region, each exposing a SOCKS5
# proxy on 0.0.0.0:<port> (ListenInterface=any) so Railway TCP Proxy can
# reach it from outside.
#
# IMPORTANT: the datastore/ dir ships PRE-SEEDED psiphon.boltdb files (copied
# from a working server). psiphon expects its store at
#   <DataRootDirectory>/ca.psiphon.PsiphonTunnel.tunnel-core/datastore/psiphon.boltdb
# A fresh empty store means the tunnel takes a very long time to establish
# (~10+ min) and often times out; with a seeded DB the tunnel is up in
# seconds. Each region gets its own store so multiple instances don't
# contend on the same boltdb lock.

FROM debian:bookworm-slim

COPY psiphon-x86_64 /usr/local/bin/psiphon
COPY psiphon-aarch64 /usr/local/bin/psiphon-arm64
RUN chmod +x /usr/local/bin/psiphon /usr/local/bin/psiphon-arm64

# Region configs (one JSON per country, ports 1081..1103). Each config points
# its DataRootDirectory at /data/<REGION>.
COPY configs/ /etc/psiphon/configs/

# Pre-seeded datastores per region — laid out EXACTLY like psiphon expects:
# /data/<REGION>/ca.psiphon.PsiphonTunnel.tunnel-core/datastore/psiphon.boltdb
COPY datastore/ /data/

# Entrypoint: starts the requested regions as background jobs, then waits.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default regions — override with REGIONS env var, e.g. REGIONS="DE FR CH GB"
ENV REGIONS="DE FR CH"

EXPOSE 1084 1086 1090

ENTRYPOINT ["/entrypoint.sh"]