// Package popocore embeds sing-box behind an API narrow enough to cross a
// language boundary.
//
// Everything here is designed for gomobile on Android and iOS and for cgo on
// desktop, which constrains the surface hard: exported functions take and return
// only strings, ints and bools, and errors come back as strings. That is why the
// configuration arrives as a JSON string rather than as a typed object — the
// caller builds it, this side runs it.
package popocore

import (
	"context"
	"sync"
	"time"

	box "github.com/sagernet/sing-box"
	"github.com/sagernet/sing-box/constant"
	"github.com/sagernet/sing-box/include"
	"github.com/sagernet/sing-box/option"
	"github.com/sagernet/sing/common/json"
)

// State of the tunnel, as an int so it survives the language boundary.
const (
	StateStopped  = 0
	StateStarting = 1
	StateRunning  = 2
	StateStopping = 3
	StateError    = 4
)

// Tunnel owns at most one running sing-box instance.
//
// A single instance rather than a pool: the platform gives us one TUN device, so
// two running instances would fight over it. Start on an already-running tunnel
// replaces it, which is what "switch server" means.
type Tunnel struct {
	mu       sync.Mutex
	instance *box.Box
	cancel   context.CancelFunc
	state    int
	lastErr  string
	since    time.Time
}

// NewTunnel returns a stopped tunnel.
func NewTunnel() *Tunnel {
	return &Tunnel{state: StateStopped}
}

// Start brings the tunnel up with the given sing-box configuration.
//
// Returns an empty string on success and the error text otherwise. It is
// idempotent in the useful sense: starting while running stops the old instance
// first, so callers do not have to sequence stop/start themselves and cannot
// leave two instances alive by racing.
func (t *Tunnel) Start(configJSON string) string {
	return t.StartWithTun(configJSON, 0)
}

// StartWithTun is Start with a TUN descriptor the platform already opened.
//
// Android's VpnService and iOS's NetworkExtension both hand back a descriptor
// rather than letting the process open the device, and sing-box adopts it
// through a platform interface rather than through the configuration. Pass 0 on
// desktop, where sing-box opens the device itself.
func (t *Tunnel) StartWithTun(configJSON string, tunFd int) string {
	t.mu.Lock()
	defer t.mu.Unlock()

	if t.instance != nil {
		t.stopLocked()
	}

	t.state = StateStarting
	t.lastErr = ""

	ctx, cancel := context.WithCancel(context.Background())
	ctx = withPlatformTun(ctx, tunFd)
	ctx = box.Context(ctx,
		include.InboundRegistry(),
		include.OutboundRegistry(),
		include.EndpointRegistry(),
		include.DNSTransportRegistry(),
		include.ServiceRegistry(),
	)

	options, err := json.UnmarshalExtendedContext[option.Options](ctx, []byte(configJSON))
	if err != nil {
		cancel()
		return t.failLocked("parse config: " + err.Error())
	}

	instance, err := box.New(box.Options{Context: ctx, Options: options})
	if err != nil {
		cancel()
		return t.failLocked("build instance: " + err.Error())
	}

	if err := instance.Start(); err != nil {
		// Close the half-built instance; leaking it would hold the TUN device
		// and make the next Start fail for the wrong reason.
		_ = instance.Close()
		cancel()
		return t.failLocked("start: " + err.Error())
	}

	t.instance = instance
	t.cancel = cancel
	t.state = StateRunning
	t.since = time.Now()
	return ""
}

// Stop brings the tunnel down. Stopping a stopped tunnel is not an error.
func (t *Tunnel) Stop() string {
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.stopLocked()
}

func (t *Tunnel) stopLocked() string {
	if t.instance == nil {
		t.state = StateStopped
		return ""
	}

	t.state = StateStopping
	err := t.instance.Close()
	if t.cancel != nil {
		t.cancel()
	}
	t.instance = nil
	t.cancel = nil
	t.state = StateStopped
	t.since = time.Time{}

	if err != nil {
		t.lastErr = err.Error()
		return t.lastErr
	}
	return ""
}

// State returns one of the State* constants.
func (t *Tunnel) State() int {
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.state
}

// LastError returns the most recent failure text, or an empty string.
func (t *Tunnel) LastError() string {
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.lastErr
}

// UptimeSeconds is how long the current instance has been running, or 0.
func (t *Tunnel) UptimeSeconds() int {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.instance == nil || t.since.IsZero() {
		return 0
	}
	return int(time.Since(t.since).Seconds())
}

func (t *Tunnel) failLocked(message string) string {
	t.state = StateError
	t.lastErr = message
	return message
}

// CheckConfig parses a configuration without starting anything.
//
// The app validates a config before asking the platform for VPN permission, so
// a malformed one produces a plain error rather than a permission prompt
// followed by a failure.
func CheckConfig(configJSON string) string {
	ctx := box.Context(context.Background(),
		include.InboundRegistry(),
		include.OutboundRegistry(),
		include.EndpointRegistry(),
		include.DNSTransportRegistry(),
		include.ServiceRegistry(),
	)
	if _, err := json.UnmarshalExtendedContext[option.Options](ctx, []byte(configJSON)); err != nil {
		return err.Error()
	}
	return ""
}

// Version reports the embedded sing-box version, for the about screen and for
// bug reports where the exact core matters.
//
// sing-box leaves this as "unknown" unless the build stamps it via ldflags, so
// the release build is expected to set
// -X github.com/sagernet/sing-box/constant.Version=<version>.
func Version() string {
	return constant.Version
}
