# Turbo Chess Public GitHub Readiness

This document summarizes the public repository readiness state for Turbo Chess v1. It is a public-facing source release note and does not contain secret values.

## Repository status

- Public repository: `https://github.com/ChessCrusherBot/turbo-chess`
- Main branch: `main`
- Git remote: `https://github.com/ChessCrusherBot/turbo-chess.git`
- Source license: GNU General Public License version 3

## Current app state

- Turbo Chess v1 is free and ad-free.
- The Android release app is offline-focused and does not request the `INTERNET` permission.
- No login, accounts, analytics, crash reporting, cloud sync, subscriptions, in-app purchases, Google Play Billing, active AdMob, or rewarded ads are part of the current Android release app.
- Bookmarks, settings, progress, and game history are stored locally on the device.
- More -> Legal contains the public source link: `https://github.com/ChessCrusherBot/turbo-chess`

## Security and private files

This public repository intentionally does not include Android signing keys, keystore files, local machine configuration, Play Console credentials, environment files, private API keys, or private developer account records.

Release signing files, local Android configuration, generated build outputs, and local tool caches are excluded from version control. Contributors and maintainers should use targeted staging commands and review `git status --short` before committing public documentation or source updates.

## GPLv3 and Stockfish

Turbo Chess includes Stockfish under GPLv3, so the project keeps GPLv3 license text, Stockfish source metadata, Stockfish build notes, and third-party notices in the repository.

Stockfish source availability and GPLv3 obligations remain a release responsibility whenever distributing public app binaries.

## Recommended public repository checks

- Confirm public documentation matches the current free, ad-free, offline app state.
- Confirm sensitive signing and account files remain excluded from version control.
- Confirm generated APK, AAB, and release output files are not tracked.
- Confirm third-party notices and Stockfish source/build metadata remain available.
- Confirm More -> Legal continues to show the GitHub source link for distributed releases.
