package com.popo.popo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log

/**
 * Owns the TUN device and the sing-box core for its lifetime.
 *
 * The tunnel runs in a service rather than in the activity because Android
 * tears an activity down whenever it feels like it, and a VPN that dies when
 * the user switches apps is worse than no VPN: traffic silently goes back to
 * the clear.
 */
class PopoVpnService : VpnService() {

    companion object {
        const val ACTION_START = "com.popo.popo.START"
        const val ACTION_STOP = "com.popo.popo.STOP"
        const val EXTRA_CONFIG = "config"
        const val EXTRA_FINGERPRINT = "fingerprint"

        private const val TAG = "PopoVpnService"
        private const val NOTIFICATION_CHANNEL = "popo_tunnel"
        private const val NOTIFICATION_ID = 1

        /** Reported back to Dart through the status channel. */
        @Volatile var state: String = "disconnected"
            private set

        @Volatile var lastError: String? = null
            private set

        @Volatile var fingerprint: String? = null
            private set

        @Volatile private var startedAtMillis: Long = 0

        fun uptimeSeconds(): Int =
            if (state == "connected" && startedAtMillis > 0)
                ((System.currentTimeMillis() - startedAtMillis) / 1000).toInt()
            else 0

        /** Set by the service so the plugin can push updates without polling. */
        @Volatile var onStateChanged: (() -> Unit)? = null

        private fun publish(newState: String, error: String? = null) {
            state = newState
            lastError = error
            if (newState == "connected") {
                startedAtMillis = System.currentTimeMillis()
            } else if (newState == "disconnected" || newState == "failed") {
                startedAtMillis = 0
            }
            onStateChanged?.invoke()
        }
    }

    private var tunInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopTunnel()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                val config = intent.getStringExtra(EXTRA_CONFIG)
                fingerprint = intent.getStringExtra(EXTRA_FINGERPRINT)
                if (config.isNullOrBlank()) {
                    publish("failed", "no configuration supplied")
                    stopSelf()
                    return START_NOT_STICKY
                }
                startTunnel(config)
                // START_STICKY so Android brings the tunnel back if it kills us
                // for memory; the alternative is a silent leak to the clear.
                return START_STICKY
            }
        }
        return START_NOT_STICKY
    }

    private fun startTunnel(config: String) {
        publish("connecting")
        startForegroundNotification()

        try {
            val builder = Builder()
                .setSession("PoPo")
                .setMtu(9000)
                .addAddress("172.19.0.1", 30)
                .addRoute("0.0.0.0", 0)
                .addRoute("::", 0)
                // The app's own traffic must not re-enter the tunnel, or every
                // request loops back into itself.
                .addDisallowedApplication(packageName)

            applySplitTunnel(builder)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setMetered(false)
            }

            val descriptor = builder.establish()
            if (descriptor == null) {
                publish("failed", "the system refused to establish the VPN")
                stopSelf()
                return
            }
            tunInterface = descriptor

            // The core adopts this descriptor; it does not open a device itself.
            val error = PopoCore.startWithTun(config, descriptor.fd)
            if (error.isNotEmpty()) {
                Log.e(TAG, "core refused the configuration: $error")
                publish("failed", error)
                closeTun()
                stopSelf()
                return
            }

            publish("connected")
        } catch (e: Throwable) {
            Log.e(TAG, "start failed", e)
            publish("failed", e.message ?: e.toString())
            closeTun()
            stopSelf()
        }
    }

    /**
     * Per-app routing. Android is the only platform that offers it, which is why
     * the feature is Android-only in the UI rather than hidden elsewhere.
     */
    private fun applySplitTunnel(builder: Builder) {
        val excluded = SplitTunnelPreferences.excludedPackages(this)
        val included = SplitTunnelPreferences.includedPackages(this)

        // Android forbids mixing the two; include wins because it is the
        // stricter, more deliberate choice.
        if (included.isNotEmpty()) {
            included.forEach { runCatching { builder.addAllowedApplication(it) } }
            return
        }
        excluded.forEach { runCatching { builder.addDisallowedApplication(it) } }
    }

    private fun stopTunnel() {
        runCatching { PopoCore.stop() }
        closeTun()
        publish("disconnected")
        stopForegroundCompat()
    }

    private fun closeTun() {
        runCatching { tunInterface?.close() }
        tunInterface = null
    }

    override fun onRevoke() {
        // The user revoked VPN permission, or another VPN took over.
        Log.w(TAG, "VPN permission revoked")
        stopTunnel()
        stopSelf()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopTunnel()
        onStateChanged = null
        super.onDestroy()
    }

    private fun startForegroundNotification() {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL,
                "Tunnel",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setShowBadge(false) }
            manager.createNotificationChannel(channel)
        }

        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE,
        )

        val notification: Notification =
            Notification.Builder(this, NOTIFICATION_CHANNEL)
                .setContentTitle("PoPo")
                .setContentText("Tunnel is running")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(open)
                .setOngoing(true)
                .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    @Suppress("DEPRECATION")
    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
    }
}
