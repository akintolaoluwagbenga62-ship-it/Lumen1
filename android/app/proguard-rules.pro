# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Image picker / cached_network_image / url_launcher pull in OkHttp & Glide
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# Keep app entry points
-keep class com.lumen.app.** { *; }

# Drop debug log calls in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}
