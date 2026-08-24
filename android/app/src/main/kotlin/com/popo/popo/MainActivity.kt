package com.popo.popo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var tunnelPlugin: TunnelPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val plugin = TunnelPlugin(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
        plugin.attach(this)
        // Registered on the engine so the VPN permission result reaches the
        // plugin; without this the request would hang forever.
        flutterEngine.plugins.add(TunnelActivityAware(plugin))
        tunnelPlugin = plugin
    }

    override fun onDestroy() {
        tunnelPlugin?.detach()
        tunnelPlugin?.dispose()
        tunnelPlugin = null
        super.onDestroy()
    }
}
