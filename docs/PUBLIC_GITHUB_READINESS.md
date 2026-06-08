# Turbo Chess Public GitHub Readiness

This document records a public GitHub readiness check for the current Turbo Chess v1 source state. It does not contain secret values and is not legal advice.

## Current repo status

- Public repo: `https://github.com/ChessCrusherBot/turbo-chess`
- Branch: `main`
- Remote: `https://github.com/ChessCrusherBot/turbo-chess.git`
- The repo already has commits and tracked files.
- This document is a readiness checklist for publishing or updating the current Turbo Chess v1 source.

## Current app state

- Turbo Chess v1 is free and ad-free.
- No active AdMob, rewarded ads, subscription, Google Play Billing, or in-app purchase path remains in Android runtime source.
- No login, analytics, crash reporting, or cloud sync is used in the release app.
- Release APK has no user-requested dangerous permissions.
- More -> Legal contains the source link: `https://github.com/ChessCrusherBot/turbo-chess`

## Files that must not be published

Do not publish or stage these local/private files and generated outputs:

- `android/app/upload-keystore.jks`
- `android/keystore.properties`
- `android/local.properties`
- `*.jks`
- `*.keystore`
- `key.properties`
- `keystore.properties`
- `.env`
- Play Console/service account JSON files
- `release_outputs/`
- `release_package/`
- `build/`
- `.dart_tool/`
- `.gradle/`
- APK/AAB files
- Private handoff/report files not intended for GitHub

## Current safety status

- Sensitive signing/local files may exist locally, but they are ignored and must remain untracked.
- Do not use `git add .` blindly.
- Review `git status --short` before committing.
- Use targeted `git add` commands only.
- Do not print or commit secret contents.

## Stockfish / GPLv3 reminder

- Turbo Chess includes Stockfish.
- Stockfish is GPLv3.
- GPLv3 license text and Stockfish source/build notes are included in the project.
- Final human Stockfish GPLv3/source availability review is still required before Play Store upload.
- This document does not claim final legal compliance.

## Recommended pre-push checks

- `git status --short`
- `git ls-files`
- Verify sensitive files are ignored.
- Verify no APK/AAB files are tracked.
- Verify no keystore/password files are tracked.
- Verify old ads/subscription runtime code is absent.
- Verify More -> Legal contains the GitHub source link.
- Verify README and notices match the current free/ad-free/offline app state.
