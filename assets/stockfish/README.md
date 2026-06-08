# Stockfish Licensing Assets

This directory keeps Stockfish license, authorship, and source metadata for Turbo Chess.

Turbo Chess packages Stockfish as Android native libraries in:

* `android/app/src/main/jniLibs/arm64-v8a/libstockfish.so`
* `android/app/src/main/jniLibs/armeabi-v7a/libstockfish.so`
* `android/app/src/main/jniLibs/x86_64/libstockfish.so`

The app does not load a runnable engine binary from this asset directory.

See `STOCKFISH_SOURCE.txt` for the recorded upstream Stockfish release, tag, commit, ABI list, and build-note locations.
