# Turbo Chess Source Release Secret Checklist

This file records a non-destructive local source-release safety pass. Secret values were not printed or copied.

## Files Generally Safe To Publish After Final Review

* `lib/`
* `android/` source and build configuration, excluding private local/signing files
* `assets/positions/`
* `assets/pieces/`
* `assets/sounds/`
* `assets/legal/`
* `assets/stockfish/`
* `android/app/src/main/jniLibs/` Stockfish binaries, if intentionally included with the source package
* `test/`
* `pubspec.yaml`
* `pubspec.lock`
* `LICENSE`
* `README.md`
* `THIRD_PARTY_NOTICES.md`
* `docs/`
* `release_readiness/`

## Files That Must Not Be Published

* Keystore files
* Keystore passwords
* `android/key.properties`
* `android/keystore.properties`
* `android/local.properties`
* Play Console service account JSON files
* `client_secret*.json`
* `.env` files
* private API keys or tokens
* developer payment/tax records
* generated `build/` output
* `.dart_tool/`
* Gradle caches
* `release_outputs/`
* raw Lichess PGN/ZST inputs
* generated position-factory reports unless deliberately reviewed

## Sensitive Or Private Files Found Locally

* `android/app/upload-keystore.jks` exists and contains sensitive signing material.
* `android/keystore.properties` exists and contains sensitive signing material.
* `android/local.properties` exists and contains local machine configuration.

These files must stay private. Their contents were not printed.

## Additional Review Paths

* `release_package/` exists and should stay ignored unless deliberately reviewed for public documentation.
* `screenshots/` contains generated screenshots, including older screenshot names that mention ads. Use only fresh screenshots from the latest release APK for Play Store assets.
* `tools/position_factory/reports/` contains large generation reports and local source paths. Keep ignored unless deliberately reviewed.
* `PROJECT_HANDOFF_FOR_CHATGPT.md`, `SUBSCRIPTION_REMOVAL_AND_REWARDED_PASS_REPORT.md`, and `git_status_now.txt` are local project notes; review before any public source push.

## .gitignore Status

`.gitignore` already excludes local properties, keystore files, env files, service-account/client-secret JSON files, build output, Gradle caches, raw PGN/ZST files, and position-factory reports.

This pass added `/release_outputs/` to `.gitignore` because APK/AAB release artifacts are generated build outputs and should not be part of a public source release.

## Search Summary

Path-only scans found signing/property references in expected documentation and Gradle configuration files. No secret values were printed. Monetization-related strings remain only in tests/docs that assert old ad/billing behavior is absent or in historical local notes that should be reviewed before public source release.
