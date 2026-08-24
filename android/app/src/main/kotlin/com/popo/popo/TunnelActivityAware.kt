package com.popo.popo

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * Routes activity results to [TunnelPlugin].
 *
 * The VPN permission prompt returns through onActivityResult, so the plugin has
 * to be registered as activity-aware or the request never completes and the Dart
 * side waits forever on a future that cannot resolve.
 */
class TunnelActivityAware(private val plugin: TunnelPlugin) : FlutterPlugin, ActivityAware {

    private var binding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addActivityResultListener(plugin)
        plugin.attach(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        binding?.removeActivityResultListener(plugin)
        binding = null
        plugin.detach()
    }
}
