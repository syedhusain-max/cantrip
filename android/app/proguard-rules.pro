# Flutter's engine calls into these over JNI, so the shrinker can't see the
# references and would otherwise strip them.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter's embedding references Play Core's deferred-component APIs, but
# this app doesn't use deferred components, so the library isn't on the
# classpath and R8 fails on the dangling references. Don't warn rather than
# pull in a dependency for a feature we don't ship.
-dontwarn com.google.android.play.core.**
