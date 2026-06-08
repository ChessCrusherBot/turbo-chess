# Turbo Chess Open-Source Release Notes

## Purpose

Turbo Chess is released as GPLv3 open source because the project includes Stockfish, which is GPLv3 licensed.

This document summarizes the public source package and related release responsibilities.

## Public source materials

The public repository includes:

- Flutter/Dart source code
- Android project files needed to build the app
- `pubspec.yaml` and `pubspec.lock`
- tests
- third-party notices
- GPLv3 license text
- Stockfish source and build metadata
- build instructions

## Security and private files

This public repository intentionally does not include Android signing keys, keystore files, local machine configuration, Play Console credentials, environment files, private API keys, or private developer account records.

Release signing and local configuration remain private to each developer or release environment.

## Current app state

The current Turbo Chess Android release is free, ad-free, offline-focused, and local-only. It does not include an ad SDK, active AdMob, rewarded ads, subscriptions, in-app purchases, account/login systems, analytics, crash reporting, cloud sync, in-app payments, or Google Play Billing.

The Android release app does not request the `INTERNET` permission.

## Stockfish details

Turbo Chess bundles these Stockfish binaries:

- `android/app/src/main/jniLibs/arm64-v8a/libstockfish.so`
- `android/app/src/main/jniLibs/armeabi-v7a/libstockfish.so`
- `android/app/src/main/jniLibs/x86_64/libstockfish.so`

Recorded source information:

- Source URL: https://github.com/official-stockfish/Stockfish
- Version: Stockfish 18
- Tag: `sf_18`
- Commit: `cb3d4ee9b47d0c5aae855b12379378ea1439675c`
- Build notes: `lib/core/engine/BUILDING_STOCKFISH.md`
- Bundled legal mirror: `assets/legal/STOCKFISH_SOURCE.txt`

No Stockfish source modifications are included in this repository. The project metadata records the intended upstream version. Binary equivalence cannot be proven from the binary alone.

## Release maintenance notes

Maintainers should review source availability, GPLv3 obligations, third-party notices, Android permissions, and Play Console Data Safety answers whenever distributing a public app binary.

If app behavior changes in a future version, this document and the public README should be updated to match the released app.

## Suggested verification checks

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- debug APK build
- release APK build
- split ABI release APK build
- release AAB build
- archive inspection for Stockfish binaries
- archive inspection for legal files
- More > Legal smoke test
- secret scan
- confirm GitHub source is public when shipping a corresponding Play Store release
