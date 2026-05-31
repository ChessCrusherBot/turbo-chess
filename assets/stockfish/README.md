# Stockfish Licensing Assets

This directory no longer contains the runnable engine binary.

Turbo Chess now packages Stockfish as Android native libraries in:

- `android/app/src/main/jniLibs/arm64-v8a/libstockfish.so`
- `android/app/src/main/jniLibs/armeabi-v7a/libstockfish.so`
- `android/app/src/main/jniLibs/x86_64/libstockfish.so` for emulator verification

These assets are kept so the app ships the upstream license, authorship, and
source-build metadata alongside the app bundle.

See `STOCKFISH_SOURCE.txt` for the exact upstream source used.
