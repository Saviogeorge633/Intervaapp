# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive
-keep class com.hivedb.** { *; }
-keep interface com.hivedb.** { *; }
-keep public class * extends com.hivedb.hive.TypeAdapter
-keep class * implements com.hivedb.hive.TypeAdapter

# Keep your model classes and their adapters
-keep class com.example.interva.models.** { *; }
-keep class com.example.interva.models.*Adapter { *; }

# Also keep Shared Preferences classes if needed
-keep class com.google.gson.** { *; }

# Ignore missing Play Store classes (Flutter Engine references these optionally for deferred components)
-dontwarn com.google.android.play.core.**
