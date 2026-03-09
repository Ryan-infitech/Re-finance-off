# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# Keep sqflite
-keep class com.tekartik.sqflite.** { *; }

# Obfuscation
-repackageclasses ''
-allowaccessmodification

# Missing Play Core classes (used by Flutter deferred components)
-dontwarn com.google.android.play.core.**
-useuniqueclassmembernames
