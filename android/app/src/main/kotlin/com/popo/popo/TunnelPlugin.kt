package com.popo.popo

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Bridges Dart's TunnelService to the VPN service.
 *
 * The channel names and payload shape are the contract in
 * lib/core/tunnel/tunnel_service.dart; changing one without the other silently
 * breaks the connection with no compiler to catch it.
 */
class TunnelPlugin(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.ActivityResultListener {

    companion object {
        private const val METHOD_CHANNEL = "popo/tunnel"
        private const val EVENT_CHANNEL = "popo/tunnel/status"
        private const val REQUEST_VPN_PERMISSION = 0x5011
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)

    private var activity: Activity? = null
    private var events: EventChannel.EventSink? = null
    private var pendingPermission: MethodChannel.Result? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun attach(activity: Activity) {
        this.activity = activity
    }

    fun detach() {
        activity = null
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        PopoVpnService.onStateChanged = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermission" -> requestPermission(result)
            "start" -> start(call, result)
            "stop" -> stop(result)
            "status" -> result.success(statusMap())
            "isCoreAvailable" -> result.success(PopoCore.isAvailable)
            "coreVersion" -> result.success(PopoCore.version())
            "setSplitTunnel" -> setSplitTunnel(call, result)
            else -> result.notImplemented()
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(context)
        if (intent == null) {
            // Already granted; VpnService.prepare returns null in that case.
            result.success(true)
            return
        }

        val current = activity
        if (current == null) {
            result.error("no_activity", "cannot ask for permission with no activity", null)
            return
        }

        // Only one prompt can be outstanding; a second request would orphan the
        // first result and hang that call forever.
        if (pendingPermission != null) {
            result.error("busy", "a permission request is already in progress", null)
            return
        }

        pendingPermission = result
        current.startActivityForResult(intent, REQUEST_VPN_PERMISSION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_VPN_PERMISSION) return false
        pendingPermission?.success(resultCode == Activity.RESULT_OK)
        pendingPermission = null
        return true
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        val config = call.argument<String>("config")
        if (config.isNullOrBlank()) {
            result.error("bad_config", "no configuration supplied", null)
            return
        }
        if (VpnService.prepare(context) != null) {
            result.error("permission_denied", "VPN permission has not been granted", null)
            return
        }

        val intent = Intent(context, PopoVpnService::class.java).apply {
            action = PopoVpnService.ACTION_START
            putExtra(PopoVpnService.EXTRA_CONFIG, config)
            putExtra(PopoVpnService.EXTRA_FINGERPRINT, call.argument<String>("fingerprint"))
        }
        context.startForegroundService(intent)
        result.success(null)
    }

    private fun stop(result: MethodChannel.Result) {
        context.startService(
            Intent(context, PopoVpnService::class.java).apply {
                action = PopoVpnService.ACTION_STOP
            },
        )
        result.success(null)
    }

    private fun setSplitTunnel(call: MethodCall, result: MethodChannel.Result) {
        val mode = call.argument<String>("mode") ?: "off"
        val packages = call.argument<List<String>>("packages") ?: emptyList()

        when (mode) {
            "include" -> {
                SplitTunnelPreferences.setIncluded(context, packages)
                SplitTunnelPreferences.setExcluded(context, emptyList())
            }
            "exclude" -> {
                SplitTunnelPreferences.setExcluded(context, packages)
                SplitTunnelPreferences.setIncluded(context, emptyList())
            }
            else -> {
                SplitTunnelPreferences.setIncluded(context, emptyList())
                SplitTunnelPreferences.setExcluded(context, emptyList())
            }
        }
        result.success(null)
    }

    private fun statusMap(): Map<String, Any?> = mapOf(
        "state" to PopoVpnService.state,
        "uptimeSeconds" to PopoVpnService.uptimeSeconds(),
        "error" to PopoVpnService.lastError,
        "fingerprint" to PopoVpnService.fingerprint,
    )

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
        PopoVpnService.onStateChanged = {
            // The service publishes from its own thread; the event sink has to
            // be touched on the main thread.
            activity?.runOnUiThread { events?.success(statusMap()) }
        }
        sink?.success(statusMap())
    }

    override fun onCancel(arguments: Any?) {
        PopoVpnService.onStateChanged = null
        events = null
    }
}
