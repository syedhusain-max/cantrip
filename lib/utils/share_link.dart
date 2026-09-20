import 'package:flutter/foundation.dart';

/// Where the web build is served from, used to build a shareable link when
/// the app isn't running in a browser and so has no origin of its own.
///
/// Supplied at build time so it follows the deployment rather than being
/// hard-coded: the Pages workflow passes the site's own URL, and an Android
/// build should be given the same one:
///
/// ```
/// flutter build appbundle \
///   --dart-define=SHARE_BASE_URL=https://owner.github.io/promptcraft
/// ```
///
/// The default is a placeholder. A link copied from a build that didn't
/// define this points nowhere real, which is why the Android release
/// checklist includes it.
const shareBaseUrl = String.fromEnvironment(
  'SHARE_BASE_URL',
  defaultValue: 'https://promptcraft.app',
);

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
