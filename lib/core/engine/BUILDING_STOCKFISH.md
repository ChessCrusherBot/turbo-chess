# Stockfish Build Notes

Turbo Chess packages Stockfish from the official upstream source as Android
native libraries and discovers the active binary at runtime from
`nativeLibraryDir/libstockfish.so`.

## Upstream source

- Repository: `https://github.com/official-stockfish/Stockfish`
- Release: `Stockfish 18`
- Tag: `sf_18`
- Commit: `cb3d4ee9b47d0c5aae855b12379378ea1439675c`

## Packaged ABIs

- `android/app/src/main/jniLibs/arm64-v8a/libstockfish.so`
- `android/app/src/main/jniLibs/armeabi-v7a/libstockfish.so`
- `android/app/src/main/jniLibs/x86_64/libstockfish.so`

`x86_64` is kept for emulator verification. Release builds still filter to
device ABIs unless `split-per-abi` is enabled.

## Windows build flow used here

1. Clone the official upstream repository.
2. Checkout the stable `sf_18` tag.
3. Put the Android NDK `make.exe` on `PATH`.
4. Put the Android LLVM toolchain on `PATH`.
5. Put Git `usr/bin` on `PATH` so Stockfish's Makefile can use `sh`, `grep`,
   `sed`, and related utilities.
6. Build each ABI with the official Makefile:

```powershell
$gitUsr = 'C:\Program Files\Git\usr\bin'
$makeBin = 'C:\Users\<user>\AppData\Local\Android\Sdk\ndk\28.2.13676358\prebuilt\windows-x86_64\bin'
$toolBin = 'C:\Users\<user>\AppData\Local\Android\Sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin'
$env:PATH = "$gitUsr;$toolBin;$env:PATH"
$env:SHELL = "$gitUsr\sh.exe"

& "$makeBin\make.exe" objclean
& "$makeBin\make.exe" build ARCH=x86-64 COMP=ndk

& "$makeBin\make.exe" objclean
& "$makeBin\make.exe" build ARCH=armv8 COMP=ndk

& "$makeBin\make.exe" objclean
& "$makeBin\make.exe" build ARCH=armv7 COMP=ndk
```

7. Copy the resulting `stockfish` executable into the matching `jniLibs` ABI
   folder as `libstockfish.so`.

## Runtime verification

- Dart runtime: `lib/core/engine/stockfish_engine.dart`
- Manager: `lib/core/engine/engine_manager.dart`
- Android bridge: `android/app/src/main/kotlin/com/turbochess/app/MainActivity.kt`

The health check verifies:

- binary exists
- process starts
- UCI handshake succeeds
- `isready` succeeds
- a legal `bestmove` is returned for a known FEN
- an evaluation score is returned
