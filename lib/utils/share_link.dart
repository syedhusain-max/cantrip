import 'package:flutter/foundation.dart';

/// Where the web build is served from, used to build a shareable link when
/// the app isn't running in a browser and so has no origin of its own.
///
/// This is a placeholder until the domain is chosen and the web build is
/// deployed: links copied from the Android app point here, so they are only
/// as real as this value. Update it in one place when the domain lands.
const shareBaseUrl = 'https://promptcraft.app';

/// Absolute, pasteable link to an in-app [route] (e.g. `/prompt/var_x`).
///
/// On web this is built from the page's own origin, so it stays correct
/// under whatever host, port or sub-directory the build is served from —
/// including a local `flutter run`. Everywhere else it falls back to
/// [shareBaseUrl].
///
/// The `#` is not decoration: the app uses go_router's hash strategy, so a
/// link without it would ask the server for a path it doesn't serve.
String shareLinkFor(String route) {
  final path = route.startsWith('/') ? route : '/$route';
  if (!kIsWeb) return '$shareBaseUrl/#$path';

  final base = Uri.base;
  final directory = base.path.endsWith('/')
      ? base.path
      : base.path.substring(0, base.path.lastIndexOf('/') + 1);
  return '${base.origin}$directory#$path';
}
