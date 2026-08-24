package com.popo.popo

import android.content.Context

/**
 * Split-tunnel selections, read by the VPN service when it builds the interface.
 *
 * Stored natively rather than passed with the config because Android applies
 * per-app rules through VpnService.Builder, not through sing-box: by the time
 * the core sees the descriptor, the routing decision has already been made.
 */
object SplitTunnelPreferences {
    private const val FILE = "popo_split_tunnel"
    private const val KEY_EXCLUDED = "excluded"
    private const val KEY_INCLUDED = "included"

    fun excludedPackages(context: Context): Set<String> = read(context, KEY_EXCLUDED)

    fun includedPackages(context: Context): Set<String> = read(context, KEY_INCLUDED)

    fun setExcluded(context: Context, packages: List<String>) =
        write(context, KEY_EXCLUDED, packages)

    fun setIncluded(context: Context, packages: List<String>) =
        write(context, KEY_INCLUDED, packages)

    private fun read(context: Context, key: String): Set<String> =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .getStringSet(key, emptySet()) ?: emptySet()

    private fun write(context: Context, key: String, packages: List<String>) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(key, packages.toSet())
            .apply()
    }
}
