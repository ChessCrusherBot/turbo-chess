# Public GitHub Source Readiness

This document summarizes the public source-release state for Turbo Chess.

## Public repository

* Repository: `https://github.com/ChessCrusherBot/turbo-chess`
* Default branch: `main`
* Package ID: `com.turbochess.app`
* Source license: GNU General Public License version 3

## Current app state

Turbo Chess v1 is a Flutter/Dart Android chess training app with 30,000 bundled offline drill positions. Opening, Middlegame, and Endgame drills are included, and Play vs Computer uses Stockfish.

The current Android release is free, ad-free, offline-focused, and local-only. It does not use login accounts, analytics, crash reporting, cloud sync, subscriptions, in-app purchases, Google Play Billing, rewarded ads, or an ad SDK.

The Android release app does not request the `INTERNET` permission. Bookmarks, settings, progress, active games, and game history are stored locally on the device.

More -> Legal includes the public source repository link.

## Private files excluded from source

The public repository intentionally excludes Android signing keys, keystore files, local machine configuration, Play Console credentials, environment files, private API keys, and private developer account records.

Generated build outputs, APK/AAB artifacts, local tool caches, and private release packages are also excluded from version control.

## Source/license notes

Turbo Chess source code is released under GPLv3 because the Android app includes Stockfish, which is GPLv3 licensed.

The repository keeps GPLv3 license text, third-party notices, Stockfish source metadata, and Stockfish build notes available for source users.

Stockfish source availability remains a release responsibility whenever public app binaries are distributed.

## Maintainer checks

Maintainers should verify the tracked file list, public documentation, third-party notices, Stockfish source/build metadata, Android release permissions, and private-file exclusions whenever preparing a public release.
