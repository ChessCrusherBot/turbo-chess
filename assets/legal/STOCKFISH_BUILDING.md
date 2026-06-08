# Stockfish Build Notes

Turbo Chess packages Stockfish from the official upstream source as Android native libraries. The Android app discovers the active engine binary at runtime from `nativeLibraryDir/libstockfish.so`.

## Upstream source

* Repository: `https://github.com/official-stockfish/Stockfish`
* Release: Stockfish 18
* Tag: `sf_18`
* Commit: `cb3d4ee9b47d0c5aae855b12379378ea1439675c`

## Packaged ABIs

* `android/app/src/main/jniLibs/arm64-v8a/libstockfish.so`
* `android/app/src/main/jniLibs/armeabi-v7a/libstockfish.so`
* `android/app/src/main/jniLibs/x86_64/libstockfish.so`

`x86_64` is kept for emulator verification. Release builds can still filter to device ABIs unless `split-per-abi` is enabled.

## Recorded Windows build flow

1. Clone the official upstream Stockfish repository.
2. Checkout the stable `sf_18` tag.
3. Put the Android NDK `make.exe` on `PATH`.
4. Put the Android LLVM toolchain on `PATH`.
5. Put Git `usr/bin` on `PATH` so Stockfish's Makefile can use `sh`, `grep`, `sed`, and related utilities.
6. Build each ABI with the official Makefile.

Example path placeholders:

* `<GIT_INSTALL>`: Git for Windows install directory.
* `<ANDROID_NDK>`: Android NDK directory.
* `<PROJECT_ROOT>`: local Turbo Chess checkout.

```powershell
$gitUsr = '<GIT_INSTALL>\usr\bin'
$makeBin = '<ANDROID_NDK>\prebuilt\windows-x86_64\bin'
$toolBin = '<ANDROID_NDK>\toolchains\llvm\prebuilt\windows-x86_64\bin'
$env:PATH = "$gitUsr;$toolBin;$env:PATH"
$env:SHELL = "$gitUsr\sh.exe"

& "$makeBin\make.exe" objclean
& "$makeBin\make.exe" build ARCH=x86-64 COMP=ndk

& "$makeBin\make.exe" objclean
& "$makeBin\make.exe" build ARCH=armv8 COMP=ndk

& "$makeBin\make.exe" objclean
& "$makeBin\make.exe" build ARCH=armv7 COMP=ndk
```

7. Copy the resulting `stockfish` executable into the matching `jniLibs` ABI folder as `libstockfish.so`.

Example copy destination:

```powershell
Copy-Item stockfish '<PROJECT_ROOT>\android\app\src\main\jniLibs\<ABI>\libstockfish.so'
```

## Runtime verification

Runtime integration files:

* `lib/core/engine/stockfish_engine.dart`
* `lib/core/engine/engine_manager.dart`
* `android/app/src/main/kotlin/com/turbochess/app/MainActivity.kt`

The app health check verifies that the binary exists, the process starts, the UCI handshake succeeds, `isready` succeeds, a legal `bestmove` is returned for a known FEN, and an evaluation score is returned.

## Source correspondence note

No Stockfish source modifications are included in this repository. The project metadata records the intended upstream version. Binary equivalence cannot be proven from the binary alone.
