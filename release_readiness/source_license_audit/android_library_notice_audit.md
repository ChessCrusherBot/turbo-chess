# Turbo Chess Android Library Notice Audit

## Files Inspected

* `android/app/build.gradle.kts`
* `android/app/src/main/AndroidManifest.xml`
* `pubspec.lock`
* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`
* app Legal text in `lib/features/more/presentation/more_screen.dart`

## Android Library Findings

`android/app/build.gradle.kts` declares:

* `com.google.android.play:core:1.10.3`
* `androidx.multidex:multidex:2.0.1`

`multiDexEnabled = true` is set in `defaultConfig`.

Public Legal text and third-party notices include an Android build libraries notice saying Android Play Core and AndroidX multidex are Android support libraries and are not monetization features.

## Manifest Findings

The main Android manifest removes `android.permission.FOREGROUND_SERVICE` with `tools:node="remove"`.

Debug/profile manifests include `INTERNET` for Flutter development tooling. The release/main manifest is expected not to request `INTERNET`.

## Release APK Permission Check

Checked with Android SDK `aapt dump permissions` after the release rebuild in this task.

APKs checked:

* `build/app/outputs/flutter-apk/app-release.apk`
* `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
* `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
* `build/app/outputs/flutter-apk/app-x86_64-release.apk`

Only permission found in each APK:

* `com.turbochess.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`

Confirmed absent from the rebuilt release APKs:

* `android.permission.INTERNET`
* `android.permission.ACCESS_NETWORK_STATE`
* `android.permission.FOREGROUND_SERVICE`
* `com.google.android.gms.permission.AD_ID`
* billing permissions

`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` is the expected AndroidX/Flutter internal receiver-protection permission and should be left alone unless a future Android-specific review proves it is safe to remove.
