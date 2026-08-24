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

## Downloads — which file?

**کدام فایل را بگیرم؟** اگر گوشی اندروید معمولی دارید:
**`...android-arm64-most-phones.apk`** — همان یکی. بقیه را نادیده بگیرید.

| If you have | Download |
|---|---|
| **An Android phone** (almost certainly this one) | `PoPo-v0.1.0-android-arm64-most-phones-*.apk` |
| An Android phone from before ~2016 | `PoPo-v0.1.0-android-arm32-older-phones-*.apk` |
| An Android emulator on a PC | `PoPo-v0.1.0-android-x86_64-emulator-*.apk` |
| To build the Linux app yourself | `PoPo-v0.1.0-linux-x64-core-library-*.tar.gz` |
| To review the interface in a browser | `PoPo-v0.1.0-web-design-canvas-*.tar.gz` |

If you pick the wrong Android one, it simply refuses to install — nothing breaks.

The trailing `-YYYYMMDD-HHMM` is when the file was built, in UTC. Every file
from one release shares it, so you can always tell which build you have.

### Installing on Android

1. Download the `.apk` on the phone.
2. Open it. Android will ask to allow installing from this source — that is the
   normal prompt for anything not from Play, and you can revoke it afterwards.
3. The first connection asks for VPN permission. Nothing routes without it.

The web canvas is not an app: unpack it and open `index.html`. It shows all 22
screens for review and cannot tunnel, because browsers have no raw sockets.

Checksums for every file are in `SHA256SUMS.txt`.

### A note on signing

These are signed with Android's debug key, which is what the project ships with
today. They install and run, but two things follow: do not treat the signature
as proof of origin, and a later properly-signed build will not update over them
— uninstall first.

## A word about the servers

These endpoints are published by strangers on the open internet. They are fine
for getting around a block. Do not enter banking credentials over them.
