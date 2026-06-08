# Open Source Release Notes

This document summarizes the public source package for Turbo Chess v1.

## Source license

Turbo Chess source code is released under the GNU General Public License version 3. The full license text is available in the root `LICENSE` and `COPYING` files.

## Stockfish

Turbo Chess includes Stockfish, which is licensed under GPLv3.

Recorded Stockfish source information:

* Source URL: https://github.com/official-stockfish/Stockfish
* Version: Stockfish 18
* Tag: `sf_18`
* Commit: `cb3d4ee9b47d0c5aae855b12379378ea1439675c`

Bundled Android Stockfish binary paths used by the app:

* `android/app/src/main/jniLibs/arm64-v8a/libstockfish.so`
* `android/app/src/main/jniLibs/armeabi-v7a/libstockfish.so`
* `android/app/src/main/jniLibs/x86_64/libstockfish.so`

No Stockfish source modifications are included in this repository. The project metadata records the intended upstream version. Binary equivalence cannot be proven from the binary alone.

## Third-party notices

Third-party code and asset notices are documented in:

* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`
* `assets/legal/`
* `assets/stockfish/`
* `assets/pieces/cburnett_bsd/`
* `assets/sounds/chess/`

## Current app state

Turbo Chess v1 is free, ad-free, offline-focused, and local-only. It does not use login accounts, analytics, crash reporting, cloud sync, subscriptions, in-app purchases, Google Play Billing, rewarded ads, or an ad SDK.

The Android release app does not request the `INTERNET` permission.

## Source availability notes

The public repository includes the Flutter/Dart app source, Android project files, bundled training position files, tests, third-party notices, GPLv3 license text, and Stockfish source/build metadata.

Release signing files, local configuration, Play Console credentials, APK/AAB outputs, and private developer records are excluded from source control.

Maintainers should re-check source availability, GPLv3 obligations, third-party notices, Android release permissions, and Play Console declarations whenever distributing public app binaries.
