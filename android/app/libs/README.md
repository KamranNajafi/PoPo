# Native core

`popocore.aar` goes here, built by `tool/build_core_android.sh`.

It is not committed: it is ~30MB per architecture and is reproducible from
`core/`. CI builds it on every release.

Without it the app still builds and runs — discovery, health testing and the
whole interface work — and connecting reports that the core is missing.
