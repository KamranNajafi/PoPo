package popocore

import (
	"net"
	"strings"
	"testing"
	"time"
)

// A configuration that needs no privileges: a SOCKS listener on loopback going
// straight out. It exercises the same parse → build → start → stop path a real
// tunnel takes, without needing a TUN device or a live server.
func localConfig(port int) string {
	return `{
	  "log": {"level": "error"},
	  "inbounds": [
	    {"type": "mixed", "tag": "local", "listen": "127.0.0.1", "listen_port": ` + itoa(port) + `}
	  ],
	  "outbounds": [{"type": "direct", "tag": "direct"}]
	}`
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var digits []byte
	for n > 0 {
		digits = append([]byte{byte('0' + n%10)}, digits...)
		n /= 10
	}
	return string(digits)
}

func freePort(t *testing.T) int {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("no free port: %v", err)
	}
	defer listener.Close()
	return listener.Addr().(*net.TCPAddr).Port
}

func TestStartStop(t *testing.T) {
	port := freePort(t)
	tunnel := NewTunnel()

	if err := tunnel.Start(localConfig(port)); err != "" {
		t.Fatalf("start: %s", err)
	}
	if got := tunnel.State(); got != StateRunning {
		t.Fatalf("state = %d, want running", got)
	}

	// Proof it is actually listening, rather than merely reporting success.
	conn, err := net.DialTimeout("tcp", "127.0.0.1:"+itoa(port), 2*time.Second)
	if err != nil {
		t.Fatalf("tunnel reported running but nothing is listening: %v", err)
	}
	conn.Close()

	if err := tunnel.Stop(); err != "" {
		t.Fatalf("stop: %s", err)
	}
	if got := tunnel.State(); got != StateStopped {
		t.Fatalf("state = %d, want stopped", got)
	}

	// And that stopping actually released the port.
	if _, err := net.DialTimeout("tcp", "127.0.0.1:"+itoa(port), 300*time.Millisecond); err == nil {
		t.Fatal("still listening after stop")
	}
}

func TestStartReplacesRunningInstance(t *testing.T) {
	first := freePort(t)
	second := freePort(t)
	tunnel := NewTunnel()

	if err := tunnel.Start(localConfig(first)); err != "" {
		t.Fatalf("first start: %s", err)
	}
	// Switching server must not require the caller to stop first, and must not
	// leave the old instance holding its port.
	if err := tunnel.Start(localConfig(second)); err != "" {
		t.Fatalf("second start: %s", err)
	}

	conn, err := net.DialTimeout("tcp", "127.0.0.1:"+itoa(second), 2*time.Second)
	if err != nil {
		t.Fatalf("new instance not listening: %v", err)
	}
	conn.Close()

	if _, err := net.DialTimeout("tcp", "127.0.0.1:"+itoa(first), 300*time.Millisecond); err == nil {
		t.Fatal("old instance still listening after replacement")
	}

	tunnel.Stop()
}

func TestStopIsIdempotent(t *testing.T) {
	tunnel := NewTunnel()
	if err := tunnel.Stop(); err != "" {
		t.Fatalf("stopping a stopped tunnel should be fine, got %s", err)
	}
	if got := tunnel.State(); got != StateStopped {
		t.Fatalf("state = %d, want stopped", got)
	}
}

func TestBadConfigFailsWithoutLeavingStateRunning(t *testing.T) {
	tunnel := NewTunnel()

	err := tunnel.Start(`{"outbounds": [{"type": "not-a-real-protocol"}]}`)
	if err == "" {
		t.Fatal("expected an error for an unknown outbound type")
	}
	if got := tunnel.State(); got == StateRunning {
		t.Fatal("a failed start must not leave the tunnel reporting running")
	}
	if tunnel.LastError() == "" {
		t.Fatal("LastError should carry the failure")
	}
}

func TestMalformedJSONIsReportedNotPanicked(t *testing.T) {
	tunnel := NewTunnel()
	if err := tunnel.Start("{ this is not json"); err == "" {
		t.Fatal("expected a parse error")
	}
}

func TestCheckConfig(t *testing.T) {
	if err := CheckConfig(localConfig(1080)); err != "" {
		t.Fatalf("valid config rejected: %s", err)
	}
	if err := CheckConfig(`{"outbounds":[{"type":"nope"}]}`); err == "" {
		t.Fatal("invalid config accepted")
	}
	// Checking must not start anything, so the port stays free.
	listener, err := net.Listen("tcp", "127.0.0.1:1080")
	if err == nil {
		listener.Close()
	}
}

func TestUptimeOnlyCountsWhileRunning(t *testing.T) {
	tunnel := NewTunnel()
	if got := tunnel.UptimeSeconds(); got != 0 {
		t.Fatalf("stopped uptime = %d, want 0", got)
	}

	port := freePort(t)
	if err := tunnel.Start(localConfig(port)); err != "" {
		t.Fatalf("start: %s", err)
	}
	if got := tunnel.UptimeSeconds(); got < 0 {
		t.Fatalf("running uptime = %d", got)
	}
	tunnel.Stop()

	if got := tunnel.UptimeSeconds(); got != 0 {
		t.Fatalf("uptime after stop = %d, want 0", got)
	}
}

func TestVersionIsReported(t *testing.T) {
	if strings.TrimSpace(Version()) == "" {
		t.Fatal("version must not be empty")
	}
}
