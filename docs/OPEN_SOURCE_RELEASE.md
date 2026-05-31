# Turbo Chess Open-Source Release Notes

## Purpose

Turbo Chess is being prepared for GPLv3/open-source release because it bundles Stockfish, which is GPLv3 licensed.

This document is practical engineering guidance only. It is not legal advice and does not guarantee legal compliance.

## What Must Be Public

A public source release should include:

- Flutter/Dart source code
- Android source/configuration needed to build the app
- `pubspec.yaml` and `pubspec.lock`
- tests
- third-party notices
- root GPLv3 license file
- Stockfish source and build information
- build instructions

## What Must Not Be Public

Do not publish:

- keystore files
- keystore passwords
- `android/key.properties`
- `android/keystore.properties`
- Play Console service account JSON files
- `google-services.json` until it has been reviewed carefully
- `.env` files
- AdMob account secrets
- Play Console private credentials
- bank/payment information
- private API keys

## How To Publish Later

1. Review `git status`.
2. Run a secret scan manually.
3. Ensure `.gitignore` protects private files.
4. Create a public GitHub repository.
5. Push only safe files.
6. Tag releases matching Play Store versions.
7. Include APK/AAB source correspondence notes.
8. Keep signing keys and private configs outside the repo.

## Stockfish Details

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

## Play Store Note

The Play Store app can still use ads, subscriptions, and Play Billing while the source code is public. Public source release does not mean private signing credentials are public.

Users can inspect and modify GPL source, so monetization logic is visible. Do not publish signing keys, AdMob account secrets, Play Console credentials, service account JSON files, or bank/payment details.

## Pre-Release Checklist

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
