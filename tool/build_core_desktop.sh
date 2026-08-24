#!/usr/bin/env bash
# Builds the Go core as a C shared library for desktop, reached through dart:ffi.
set -euo pipefail

cd "$(dirname "$0")/.."

SING_BOX_VERSION="$(cd core && go list -m -f '{{.Version}}' github.com/sagernet/sing-box)"

case "$(uname -s)" in
  Linux)   LIB="libpopocore.so"; OUT="linux/lib" ;;
  Darwin)  LIB="libpopocore.dylib"; OUT="macos/Frameworks" ;;
  MINGW*|MSYS*|CYGWIN*) LIB="popocore.dll"; OUT="windows/lib" ;;
  *) echo "unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

mkdir -p "$OUT"

cd core
CGO_ENABLED=1 go build \
  -buildmode=c-shared \
  -tags "with_gvisor,with_quic,with_utls,with_clash_api" \
  -ldflags "-s -w -X github.com/sagernet/sing-box/constant.Version=${SING_BOX_VERSION}" \
  -o "../${OUT}/${LIB}" \
  ./cshared

echo "wrote ${OUT}/${LIB} (sing-box ${SING_BOX_VERSION})"
