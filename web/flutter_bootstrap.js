// Custom bootstrap: load the engine from files we ship, not from a CDN.
//
// By default Flutter web fetches CanvasKit from www.gstatic.com at runtime. For
// an app whose whole purpose is working where Google is unreachable, that is a
// hard dependency in exactly the wrong place — and it also makes the build
// unrenderable in any offline environment. `flutter build web` already emits
// canvaskit/ next to index.html, so point the loader there.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
