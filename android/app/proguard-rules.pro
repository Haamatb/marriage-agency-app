# Flutter Play Core Deferred Components (suppress missing warnings)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keep class dev.fluttercommunity.workmanager.** { *; }

# SQLite & Desugaring
-keep class com.tekartik.sqflite.** { *; }
-dontwarn java.time.**
-dontwarn org.threeten.bp.**

# Google / Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
