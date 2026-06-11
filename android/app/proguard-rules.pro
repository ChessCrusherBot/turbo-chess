# Keep Flutter engine and plugin classes.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter's Android embedding still contains deferred-component references to
# old Play Core task types. Turbo Chess does not use deferred components; the
# Android 14-compatible Play Feature Delivery artifact supplies the split
# install classes, and these unused task references can be ignored by R8.
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
