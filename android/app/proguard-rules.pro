# Keep Flutter engine and plugin classes.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Mobile Ads classes.
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Keep Google Play Billing classes used by in_app_purchase.
-keep class com.android.billingclient.api.** { *; }
-dontwarn com.android.billingclient.api.**
