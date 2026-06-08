# Android Library Notice Audit

## Files inspected

* `android/app/build.gradle.kts`
* `android/app/src/main/AndroidManifest.xml`
* `pubspec.lock`
* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`

## Android library findings

`android/app/build.gradle.kts` declares:

* `com.google.android.play:core:1.10.3`
* `androidx.multidex:multidex:2.0.1`

`multiDexEnabled = true` is set in `defaultConfig`.

Public notices include Android Play Core and AndroidX multidex as Android support/build libraries. They are not monetization features.

## Manifest findings

The main Android manifest removes `android.permission.FOREGROUND_SERVICE` with `tools:node="remove"`.

Debug/profile manifests include `INTERNET` for Flutter development tooling. The release/main manifest does not request `INTERNET`.

## Release permission notes

The documented Android release state is:

* `android.permission.INTERNET` is absent.
* `android.permission.ACCESS_NETWORK_STATE` is absent.
* `android.permission.FOREGROUND_SERVICE` is absent.
* `com.google.android.gms.permission.AD_ID` is absent.
* Billing permissions are absent.

`com.turbochess.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` may appear as an AndroidX/Flutter internal receiver-protection permission.
