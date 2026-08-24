# PoPo core

sing-box, wrapped in an API narrow enough to cross a language boundary.

## Why it is shaped like this

Exported functions take and return only strings, ints and bools, and errors come
back as text. That is what gomobile and cgo can carry. The configuration arrives
as a JSON string rather than as a typed object: the Dart side builds it (see
`lib/core/tunnel/`), this side runs it.

The TUN device is **not** configured through JSON. Android's `VpnService` and
iOS's `NetworkExtension` open the device themselves and hand back a file
descriptor; sing-box adopts it through a `PlatformInterface`, which is what
`platform.go` implements and what `Tunnel.StartWithTun` installs. A
`file_descriptor` key in the config makes the whole document fail to parse —
that mistake is caught by the corpus test below.

## Building

```bash
# Android: produces android/app/libs/popocore.aar
ANDROID_NDK_HOME=/path/to/ndk tool/build_core_android.sh

# Desktop: produces linux/lib/libpopocore.so (or the platform equivalent)
tool/build_core_desktop.sh
```

Both need `with_gvisor` — without it the TUN stack has no userspace mode and
cannot run unprivileged on Android.

The app builds and runs without either. Discovery, health testing and the whole
UI work; connecting reports that the native core is missing, rather than failing
somewhere confusing.

## Tests

```bash
cd core && go test ./...
```

`core_test.go` starts real sing-box instances on a loopback port and proves they
listen and then stop listening, rather than trusting a return value.

`corpus_test.go` parses every configuration the Dart test suite generates. Run
the Dart tunnel tests first:

```bash
flutter test test/tunnel_config_test.dart   # writes build/tunnel_corpus/
cd core && go test ./... -run TestGeneratedConfigs
```

Dart alone can only prove the shape it intended. A config the core rejects is a
connection that silently never happens, so the two suites check each other.
