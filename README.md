# psiphon-railway — deploy psiphon multi-region SOCKS exits on Railway

One container, multiple country SOCKS5 exit proxies, exposed via Railway TCP Proxy.
Each region gets its own fixed internal port; Railway maps each to a public
`*.proxy.rlwy.net:PORT` address.

## Regions included (pre-seeded)

| Region | Country | Internal SOCKS port |
|--------|---------|--------------------|
| DE     | Germany | 1086 |
| FR     | France  | 1090 |
| CH     | Switzerland | 1084 |

Override with `REGIONS` env var when adding more regions (needs a matching
`configs/<CC>.json` + `datastore/<CC>/psiphon.boltdb`).

## Deploy on Railway

1. Fork or push this repo to GitHub.
2. Railway → **New Project → Deploy from GitHub repo** (pick this repo).
3. Service Settings → **Networking → TCP Proxy**:
   - Add one entry per region: internal port `1086` / `1090` / `1084`.
   - Railway gives you e.g. `shuttle.proxy.rlwy.net:15140` per region.
4. Use those `host:port` pairs as SOCKS5 proxies anywhere.

## How it works

- `psiphon` (tunnel-core) runs once per region, each with a distinct config
  (`EgressRegion` + port) and its own datastore directory so multiple
  instances don't fight over the boltdb lock.
- `"ListenInterface": "any"` binds the SOCKS listener on `0.0.0.0` — required
  for Railway TCP Proxy to reach it (default is loopback only).
- `datastore/` ships pre-seeded `psiphon.boltdb` files so the tunnel
  establishes in seconds instead of 10+ minutes on an empty store.

## Local build & test

```bash
docker build -t psiphon-railway .
docker run --rm -p 1084:1084 -p 1086:1086 -p 1090:1090 psiphon-railway
# then, from the host:
curl --socks5-hostname localhost:1086 http://ip-api.com/json/   # DE
curl --socks5-hostname localhost:1090 http://ip-api.com/json/   # FR
curl --socks5-hostname localhost:1084 http://ip-api.com/json/   # CH
```

## Notes / limitations

- TCP/SOCKS5 only — no UDP (Psiphon limitation).
- Egress country is best-effort (Psiphon network picks the path).
- Exit IPs are datacenter range — fine for geo tests, not for services that
  block datacenter ASNs.
- The prebuilt binaries come from the `Thiyansa/psiphon-client` repo (MIT).