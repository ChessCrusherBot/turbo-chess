# Third-Party Notices

This file summarizes bundled third-party code and assets for Turbo Chess. It is not legal advice or a legal guarantee.

## Stockfish

- Name: Stockfish
- Type: Chess engine
- License: GNU General Public License version 3
- Version recorded by this project: Stockfish 18
- Git tag recorded by this project: `sf_18`
- Git commit recorded by this project: `cb3d4ee9b47d0c5aae855b12379378ea1439675c`
- Source URL: https://github.com/official-stockfish/Stockfish
- GPLv3 license file: `assets/stockfish/LICENSE.txt`
- Source metadata: `assets/stockfish/STOCKFISH_SOURCE.txt`
- Build notes: `lib/core/engine/BUILDING_STOCKFISH.md`
- Bundled Android binaries:
  - `android/app/src/main/jniLibs/arm64-v8a/libstockfish.so`
  - `android/app/src/main/jniLibs/armeabi-v7a/libstockfish.so`
  - `android/app/src/main/jniLibs/x86_64/libstockfish.so`

No Stockfish source modifications are included in this repository. The project metadata records the intended upstream version. Binary equivalence cannot be proven from the binary alone.

Stockfish and Turbo Chess are provided without warranty to the extent permitted by the applicable licenses.

## Wikimedia Commons / Cburnett BSD Chess Pieces

- Asset type: SVG chess pieces
- Source: Wikimedia Commons
- Author: Cburnett
- License selected for Turbo Chess: BSD license
- Local source documentation: `assets/pieces/cburnett_bsd/SOURCE.md`
- Local license file: `assets/pieces/cburnett_bsd/LICENSE.txt`
- Local verification notes: `assets/pieces/cburnett_bsd/VERIFICATION.md`

Turbo Chess selects the BSD license option offered on the Wikimedia Commons file pages for the Cburnett SVG chess pieces. Turbo Chess does not imply endorsement by Cburnett or any contributor.

## Sound Assets

- Asset type: Chess move/capture/check/checkmate sounds
- Source: OpenGameArt "Click sounds(6)"
- Author: pauliuw
- License shown on source page: CC0
- Local license documentation: `assets/sounds/chess/LICENSES.md`
- Local source documentation: `assets/sounds/chess/SOURCE.md`
- Local verification notes: `assets/sounds/chess/VERIFICATION.md`

Turbo Chess uses renamed copies of selected click MP3 files for move, capture, check, and checkmate sounds.

## Position/FEN Files

- Asset type: Opening, middlegame, and endgame FEN position files
- Included in the app/source package:
  - `assets/positions/opening_positions.txt`
  - `assets/positions/middlegame_positions.txt`
  - `assets/positions/endgame_positions.txt`
- Source documentation: `tools/position_factory/README.md`

Turbo Chess includes bundled FEN training positions derived from Lichess open database material for offline chess practice. Lichess publishes its standard open database exports under CC0. Turbo Chess does not use Lichess broadcast games.

## Turbo Chess Branding

- Asset type: Turbo Chess launcher/app icon
- Local asset: `assets/branding/turbo_chess_launcher_icon.png`
- Launcher icon generation: `flutter_launcher_icons` configuration in `pubspec.yaml`

The launcher icon is treated as a Turbo Chess project branding asset. No endorsement by any third party is implied.

## Font Awesome Free / font_awesome_flutter

- Asset type: Icon font/glyphs and Flutter package
- Font Awesome Free icons/fonts by Fonticons, Inc.
- `font_awesome_flutter` Flutter package by its contributors
- Font Awesome Free is distributed under its published free license terms, including CC BY 4.0 for SVG/JS icons, SIL OFL 1.1 for fonts, and MIT for code as applicable.
- `font_awesome_flutter` package license: MIT

Only Font Awesome Free icons are used. No Font Awesome Pro icons or private icon files are bundled.

## Google Fonts / google_fonts

- Package: `google_fonts`
- Font requested by app theme: Inter
- App code: `lib/app/theme.dart`

Turbo Chess uses the `google_fonts` package for Inter text styles. The runtime font fetching path is disabled in app startup, and the Android release manifest currently does not request the `INTERNET` permission.

## Flutter and Dart Dependencies

Flutter and Dart package dependencies are governed by their respective package licenses. See `pubspec.yaml` and `pubspec.lock` for the dependency list.

Direct dependencies currently declared in `pubspec.yaml` include:

- Flutter SDK
- `shared_preferences`
- `intl`
- `google_fonts`
- `audioplayers`
- `flutter_svg`
- `font_awesome_flutter`

Development dependencies include:

- `flutter_test`
- `flutter_lints`
- `flutter_launcher_icons`

Android Gradle dependencies currently declared in `android/app/build.gradle.kts` include:

- `com.google.android.play:core`
- `androidx.multidex:multidex`

Package license details are available from the package metadata.

## Additional Notes

- FEN source documentation is available in `tools/position_factory/README.md`.
- Turbo Chess launcher icon is treated as a project branding asset.
- Google Fonts runtime fetching is disabled; the app does not request Android `INTERNET` permission in release.
- This notice is a source summary and not legal advice or a legal guarantee.
