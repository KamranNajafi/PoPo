package popocore

import (
	"context"
	"net/netip"
	"os"

	"github.com/sagernet/sing-box/adapter"
	"github.com/sagernet/sing-box/option"
	tun "github.com/sagernet/sing-tun"
	"github.com/sagernet/sing/common/logger"
	"github.com/sagernet/sing/service"
)

// platformTun supplies a TUN device that the host platform already opened.
//
// On Android and iOS the app never opens the device itself: VpnService and
// NetworkExtension hand back a file descriptor, and sing-box has to adopt it
// rather than create its own. sing-box takes that through a PlatformInterface,
// not through the configuration — which is why the config carries no
// file_descriptor field.
//
// Every other method is a deliberate "let sing-box do it": this type exists to
// answer one question, and claiming to handle interface monitoring or DNS on top
// of that would replace working behaviour with stubs.
type platformTun struct {
	fd int
}

func (p *platformTun) Initialize(networkManager adapter.NetworkManager) error { return nil }

func (p *platformTun) UsePlatformInterface() bool { return true }

func (p *platformTun) OpenInterface(
	options *tun.Options,
	platformOptions option.TunPlatformOptions,
) (tun.Tun, error) {
	// The descriptor is owned by the platform service; sing-tun reads and writes
	// it but must not create or destroy the device.
	options.FileDescriptor = p.fd
	return tun.New(*options)
}

func (p *platformTun) UsePlatformAutoDetectInterfaceControl() bool { return false }

func (p *platformTun) AutoDetectInterfaceControl(fd int) error { return nil }

func (p *platformTun) UsePlatformDefaultInterfaceMonitor() bool { return false }

func (p *platformTun) CreateDefaultInterfaceMonitor(logger logger.Logger) tun.DefaultInterfaceMonitor {
	return nil
}

func (p *platformTun) UsePlatformNetworkInterfaces() bool { return false }

func (p *platformTun) NetworkInterfaces() ([]adapter.NetworkInterface, error) { return nil, nil }

func (p *platformTun) UnderNetworkExtension() bool { return false }

func (p *platformTun) NetworkExtensionIncludeAllNetworks() bool { return false }

func (p *platformTun) ClearDNSCache() {}

func (p *platformTun) RequestPermissionForWIFIState() error { return nil }

func (p *platformTun) ReadWIFIState() adapter.WIFIState { return adapter.WIFIState{} }

func (p *platformTun) SystemCertificates() []string { return nil }

func (p *platformTun) UsePlatformConnectionOwnerFinder() bool { return false }

func (p *platformTun) FindConnectionOwner(
	request *adapter.FindConnectionOwnerRequest,
) (*adapter.ConnectionOwner, error) {
	return nil, os.ErrInvalid
}

func (p *platformTun) UsePlatformWIFIMonitor() bool { return false }

func (p *platformTun) UsePlatformNotification() bool { return false }

func (p *platformTun) SendNotification(notification *adapter.Notification) error { return nil }

// MyInterfaceAddress reports the addresses of the app's own interface, which
// sing-box uses to avoid routing its own traffic back into the tunnel. The
// platform service already excludes the app, so there is nothing to add here.
func (p *platformTun) MyInterfaceAddress() []netip.Addr { return nil }

// withPlatformTun registers the platform interface on the context sing-box reads.
func withPlatformTun(ctx context.Context, fd int) context.Context {
	if fd <= 0 {
		return ctx
	}
	return service.ContextWith[adapter.PlatformInterface](ctx, &platformTun{fd: fd})
}
