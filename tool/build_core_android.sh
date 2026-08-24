#!/usr/bin/env bash
# Builds the Go core as an Android library and drops it where Gradle expects it.
#
# Needs the Android NDK. Without the resulting .aar the app still builds and
# runs — discovery, testing and the whole UI work — but connecting reports that
# the native core is missing, which is the honest failure.
set -euo pipefail

cd "$(dirname "$0")/.."

: "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME to your NDK path}"

OUT="android/app/libs"
mkdir -p "$OUT"

cd core

SING_BOX_VERSION="$(go list -m -f '{{.Version}}' github.com/sagernet/sing-box)"

# Installed from the version pinned in go.mod rather than @latest, for two
# reasons: gomobile refuses to run unless golang.org/x/mobile is in the module
# graph, and a floating @latest would silently change the toolchain that
# produces a release binary.
echo "installing gomobile from the pinned version…"
go install golang.org/x/mobile/cmd/gomobile golang.org/x/mobile/cmd/gobind
export PATH="$(go env GOPATH)/bin:$PATH"

gomobile init

# with_gvisor is what gives the TUN stack its userspace mode; without it the
# tun inbound cannot run unprivileged on Android.
gomobile bind \
  -target=android/arm64,android/arm,android/amd64 \
  -androidapi 24 \
  -tags "with_gvisor,with_quic,with_utls,with_clash_api" \
  -ldflags "-s -w -X github.com/sagernet/sing-box/constant.Version=${SING_BOX_VERSION}" \
  -o "../${OUT}/popocore.aar" \
  ./popocore

echo "wrote ${OUT}/popocore.aar (sing-box ${SING_BOX_VERSION})"
