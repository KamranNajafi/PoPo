# PoPo v0.1.0 — first preview

A cross-platform client that finds free proxy and tunnel endpoints, tests them,
and connects through them. Persian and English, right-to-left throughout.

**This is a preview.** The tunnel has never run on real hardware — see
*What is unverified* below before you rely on it.

## What works

**Discovery.** Search phrases are generated across five axes (protocol, noun,
qualifier, freshness, site scope) plus a Persian vocabulary, weighted so a run
spends its budget best-first. Ten search engines, each with honest capability
metadata: DuckDuckGo's HTML endpoint answers a plain client, Google and Yandex
usually do not, and Kagi cannot without credentials. Extraction handles bare
config URIs, base64 subscription payloads, and plain `ip:port` proxy tables.

**Health testing.** Latency is the time to complete a TCP handshake. It proves
something is listening and costs one round trip — it is a liveness and latency
signal, not proof that a proxy forwards traffic. Consecutive failures are
counted and dead endpoints are dropped after a configurable number, while any
success clears the streak.

**Results, saved and history.** Real pings, filters built from the protocols
actually present, saved endpoints that persist and get refreshed by later runs,
and run history.

**Import.** A subscription URL or the clipboard, through the same extractor
discovery uses. On builds without discovery this is the only way in.

**The tunnel.** sing-box v1.13.19 embedded behind a narrow API, with vless
(including Reality and Vision), vmess, trojan, shadowsocks, hysteria2, tuic and
plain socks/http, over tcp, ws, grpc, httpupgrade, http and quic. DNS is
hijacked before any other rule, because unintercepted DNS hands every hostname
to the operator the tunnel exists to get past. The kill switch is the final
outbound: proxy fails closed, direct fails open.

**Connection sharing.** A local HTTP and SOCKS listener bound to the hotspot
address specifically — `0.0.0.0` would expose the proxy on every other network
the device is attached to. Pairing is a scannable QR carrying a proxy URL.

**Split tunnelling.** Per-app routing on Android, applied through
`VpnService.Builder`.

**Two languages.** Text direction follows the locale rather than being
hardcoded, and numbers are locale-aware: ۱۲۸ under Persian, 128 under English.

## What is unverified

**Nobody has connected with this yet.** The Go core runs and its tests start
real sing-box instances; every generated configuration is parsed by the real
sing-box parser in CI. But the full path — phone, VPN permission, TUN
descriptor, traffic — has not been exercised on a device. Treat the first
connection as the real test.

**Search engine scraping is untested against live traffic.** The per-engine
result parsers were written against known SERP structure. Expect some of them
to need adjusting, and expect engines to block a plain client.

**iOS and macOS are not built here.** The Apple build path exists — discovery
and sharing compile out under `--dart-define=ENABLE_DISCOVERY=false`, verified
in CI — but no Apple binary has been produced.

## Downloads

`popo-0.1.0-<abi>.apk` — Android. Pick `arm64-v8a` unless you know otherwise.
Split per ABI so the download does not carry three copies of a 30MB core.

`popocore-0.1.0-linux-x64.tar.gz` — the desktop core, for building the Linux app.

`popo-0.1.0-web-canvas.tar.gz` — the design canvas: all 22 screens in a browser,
for reviewing the interface. It cannot tunnel; the web has no raw sockets and the
app says so rather than pretending.

Checksums are in `SHA256SUMS.txt`.

## A word about the servers

These endpoints are published by strangers on the open internet. They are fine
for getting around a block. Do not enter banking credentials over them.
