// Command cshared builds the desktop entry point: a C shared library that Dart
// reaches through dart:ffi.
//
// Mobile uses gomobile against ./popocore instead, because the tunnel there runs
// inside a platform-owned service (VpnService, NetworkExtension) that already
// speaks Java/Swift. Both paths call the same package, so the two platforms
// cannot drift apart in behaviour.
package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"unsafe"

	"github.com/kamrannajafi/popo/core/popocore"
)

// One tunnel per process. The platform gives a process one TUN device, so a
// second instance would only fight the first for it.
var tunnel = popocore.NewTunnel()

//export PopoStart
func PopoStart(configJSON *C.char) *C.char {
	return C.CString(tunnel.Start(C.GoString(configJSON)))
}

// PopoStartWithTun is PopoStart with a descriptor the host already opened.
//
//export PopoStartWithTun
func PopoStartWithTun(configJSON *C.char, tunFd C.int) *C.char {
	return C.CString(tunnel.StartWithTun(C.GoString(configJSON), int(tunFd)))
}

//export PopoStop
func PopoStop() *C.char {
	return C.CString(tunnel.Stop())
}

//export PopoState
func PopoState() C.int {
	return C.int(tunnel.State())
}

//export PopoLastError
func PopoLastError() *C.char {
	return C.CString(tunnel.LastError())
}

//export PopoUptimeSeconds
func PopoUptimeSeconds() C.int {
	return C.int(tunnel.UptimeSeconds())
}

//export PopoCheckConfig
func PopoCheckConfig(configJSON *C.char) *C.char {
	return C.CString(popocore.CheckConfig(C.GoString(configJSON)))
}

//export PopoVersion
func PopoVersion() *C.char {
	return C.CString(popocore.Version())
}

// PopoFree releases a string returned by any of the functions above.
//
// Every *C.char crossing this boundary is malloc'd by C.CString and is the
// caller's to release; without this the Dart side would leak on every status
// poll.
//
//export PopoFree
func PopoFree(pointer *C.char) {
	C.free(unsafe.Pointer(pointer))
}

func main() {}
