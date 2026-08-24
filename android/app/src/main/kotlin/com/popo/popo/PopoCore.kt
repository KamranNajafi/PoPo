package com.popo.popo

/**
 * The Go core, reached through its gomobile binding.
 *
 * The binding is produced by `gomobile bind` over `core/popocore` and dropped in
 * as `app/libs/popocore.aar`; see core/README.md. It is wrapped here rather than
 * called directly so the rest of the app depends on this small surface, and so a
 * build without the .aar fails in one obvious place instead of scattering
 * unresolved references through the service.
 */
object PopoCore {

    private val tunnel: Any? by lazy {
        runCatching {
            val clazz = Class.forName("popocore.Popocore")
            clazz.getMethod("newTunnel").invoke(null)
        }.getOrNull()
    }

    /** True when the native core is present in this build. */
    val isAvailable: Boolean
        get() = tunnel != null

    fun startWithTun(config: String, tunFd: Int): String {
        val instance = tunnel
            ?: return "the native core is missing from this build " +
                "(run tool/build_core_android.sh)"
        return runCatching {
            instance.javaClass
                .getMethod("startWithTun", String::class.java, Long::class.javaPrimitiveType)
                .invoke(instance, config, tunFd.toLong()) as String
        }.getOrElse { it.message ?: it.toString() }
    }

    fun stop(): String {
        val instance = tunnel ?: return ""
        return runCatching {
            instance.javaClass.getMethod("stop").invoke(instance) as String
        }.getOrElse { it.message ?: it.toString() }
    }

    fun version(): String = runCatching {
        Class.forName("popocore.Popocore").getMethod("version").invoke(null) as String
    }.getOrElse { "unavailable" }
}
