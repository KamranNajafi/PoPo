# PoPo v0.2.3 — Android

A cross-platform client that finds free proxy and tunnel endpoints, tests them,
and connects through them. Persian and English, right-to-left throughout.

**This is a preview.** The tunnel has never run on real hardware — see
*What is unverified* below before you rely on it.

## New in v0.2.3

**Android only, for now.** The release builds nothing but the Android app.
Desktop and the web canvas are deliberately not published: shipping a Linux
bundle that cannot connect, and a browser build that cannot tunnel at all,
gave people two downloads that were not the thing they wanted.

None of that code is gone. The desktop shell, the Linux runner and
`tool/build_core_desktop.sh` all stay in the repo, and CI still analyses,
tests and builds against them so they cannot rot while they are unpublished.
The other platforms come back by restoring two jobs in the release workflow.

## New in v0.2.2

**The Linux desktop app is actually shipped.** Previous releases carried a
`linux-x64-core-library` tarball, which is a shared library, not something you
can run. There is now a `linux-x64-app` bundle: unpack it and run `./popo`.

**Desktop no longer throws on launch.** It returned the platform-channel
tunnel implementation on the theory that the desktop embedder would answer
those channels. Nothing registers them — the generated plugin registrant is
empty — so every desktop launch raised a MissingPluginException from the status
channel before the window had finished opening. Desktop now reports the tunnel
as unsupported, which is both the fix and the truth: it finds servers and tests
them, and says plainly that it cannot connect yet. Verified by running the built
Linux binary under a headless X server: previously one exception on startup, now
none.

**The simple/advanced choice is remembered,** and its button is no longer
labelled with hardcoded English in a Persian-first app.

**The onboarding pager dots are gone.** Two dots on a single page promised a
second page that was never built.

**Two desktop defects the running app made visible.** The dashboard headline
read *Simple mode* whenever the tunnel was down — the disconnected branch was
using a settings row label instead of a status; it reads *Not connected* now.
And the sidebar was narrow enough to fade *Share connection* mid-word. Both
were found by building the Linux binary, running it under a headless X server
and clicking through the sidebar, which is not something the widget tests
could have shown.

## New in v0.2.0

**The app opens on the app.** Until now launching PoPo landed you on the design
canvas — a page of 22 screen previews, with the working app hidden behind one
button on it. Every screen existed; almost none of them were reachable. Launch
now goes to the real thing, and the canvas is a build flag
(`--dart-define=SHOW_GALLERY=true`) rather than the front door. A release build
no longer carries the previews at all, which CI checks on every push.

**Onboarding, once.** First launch explains what the app does and warns about
what these servers are. Dismissing it is remembered, so it does not come back.

**Settings, and everything under it.** A gear in the shell opens settings, and
from there: search phrases, language, connection sharing (with the pairing QR
and the device list), per-app routing, and the security screen. Eleven screens
that previously had no way in.

**A desktop window that works.** The sidebar was a picture of a sidebar — a
fixed selection with no click handler. Its seven entries now drive the content
pane on Linux, Windows and macOS.

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

**Only Android is built.** Desktop still cannot connect even when built: the
shared library exists but nothing binds to it yet, so connecting reports
unsupported rather than failing. The Apple path exists and compiles out
discovery and sharing under `--dart-define=ENABLE_DISCOVERY=false`, verified in
CI, but no Apple binary has been produced. Those targets are for later.

## Downloads — which file?

**کدام فایل را بگیرم؟** اگر گوشی اندروید معمولی دارید:
**`...android-arm64-most-phones.apk`** — همان یکی. بقیه را نادیده بگیرید.

| If you have | Download |
|---|---|
| **An Android phone** (almost certainly this one) | `PoPo-v0.2.3-android-arm64-most-phones-*.apk` |
| An Android phone from before ~2016 | `PoPo-v0.2.3-android-arm32-older-phones-*.apk` |
| An Android emulator on a PC | `PoPo-v0.2.3-android-x86_64-emulator-*.apk` |

If you pick the wrong Android one, it simply refuses to install — nothing breaks.

The trailing `-YYYYMMDD-HHMM` is when the file was built, in UTC. Every file
from one release shares it, so you can always tell which build you have.

### Installing on Android

1. Download the `.apk` on the phone.
2. Open it. Android will ask to allow installing from this source — that is the
   normal prompt for anything not from Play, and you can revoke it afterwards.
3. The first connection asks for VPN permission. Nothing routes without it.

Checksums for every file are in `SHA256SUMS.txt`.

### A note on signing

These are signed with Android's debug key, which is what the project ships with
today. They install and run, but two things follow: do not treat the signature
as proof of origin, and a later properly-signed build will not update over them
— uninstall first.

## A word about the servers

These endpoints are published by strangers on the open internet. They are fine
for getting around a block. Do not enter banking credentials over them.
