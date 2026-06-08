# Third-Party Notices

This file summarizes third-party code and assets bundled with Turbo Chess. It is a source notice summary, not legal advice.

## Turbo Chess

Turbo Chess source code is released under the GNU General Public License version 3. The full license text is available in `LICENSE` and `COPYING`.

Turbo Chess v1 is a Flutter/Dart Android chess training app. The current Android release is free, ad-free, offline-focused, and local-only.

## Stockfish

* Name: Stockfish
* Type: Chess engine
* License: GNU General Public License version 3
* Recorded version: Stockfish 18
* Recorded tag: `sf_18`
* Recorded commit: `cb3d4ee9b47d0c5aae855b12379378ea1439675c`
* Source URL: https://github.com/official-stockfish/Stockfish
* GPLv3 license file: `assets/stockfish/LICENSE.txt`
* Source metadata: `assets/stockfish/STOCKFISH_SOURCE.txt`
* Build notes: `assets/legal/STOCKFISH_BUILDING.md`

Bundled Android binary paths:

* `android/app/src/main/jniLibs/arm64-v8a/libstockfish.so`
* `android/app/src/main/jniLibs/armeabi-v7a/libstockfish.so`
* `android/app/src/main/jniLibs/x86_64/libstockfish.so`

No Stockfish source modifications are included in this repository. The project metadata records the intended upstream version. Binary equivalence cannot be proven from the binary alone.

## Cburnett Chess Pieces

* Asset type: SVG chess pieces
* Source: Wikimedia Commons
* Author: Cburnett
* License selected for Turbo Chess: BSD license
* Local source documentation: `assets/pieces/cburnett_bsd/SOURCE.md`
* Local license file: `assets/pieces/cburnett_bsd/LICENSE.txt`
* Local verification notes: `assets/pieces/cburnett_bsd/VERIFICATION.md`

Turbo Chess selects the BSD license option offered on the Wikimedia Commons file pages for the Cburnett SVG chess pieces. No endorsement by Cburnett or any contributor is implied.

## OpenGameArt Sounds

* Asset type: Chess move, capture, check, and checkmate sounds
* Source: OpenGameArt "Click sounds(6)"
* Author: pauliuw
* License shown on source page: CC0
* Local license documentation: `assets/sounds/chess/LICENSES.md`
* Local source documentation: `assets/sounds/chess/SOURCE.md`
* Local verification notes: `assets/sounds/chess/VERIFICATION.md`

Turbo Chess uses renamed copies of selected click MP3 files for chess sound effects.

## Lichess/FEN Positions / Position/FEN Files

* Asset type: Opening, middlegame, and endgame FEN position files
* Included in the app/source package:
  * `assets/positions/opening_positions.txt`
  * `assets/positions/middlegame_positions.txt`
  * `assets/positions/endgame_positions.txt`
* Source documentation: `tools/position_factory/README.md`

Turbo Chess includes bundled FEN training positions derived from Lichess open database material for offline chess practice. Lichess publishes its standard open database exports under CC0. Turbo Chess does not use Lichess broadcast games.

## Font Awesome Free / font_awesome_flutter

* Asset type: Icon font/glyphs and Flutter package
* Font Awesome Free icons/fonts by Fonticons, Inc.
* `font_awesome_flutter` Flutter package by its contributors
* `font_awesome_flutter` package license: MIT

Font Awesome Free is distributed under its published free license terms, including CC BY 4.0 for SVG/JS icons, SIL OFL 1.1 for fonts, and MIT for code as applicable.

Only Font Awesome Free icons are used. No Font Awesome Pro icons or private icon files are bundled.

## Google Fonts / Inter

* Package: `google_fonts`
* Font requested by app theme: Inter
* App code: `lib/app/theme.dart`

Turbo Chess uses the `google_fonts` package for Inter text styles. Runtime font fetching is disabled in app startup, and the Android release manifest does not request the `INTERNET` permission.

## Flutter/Dart Packages

Flutter and Dart package dependencies are governed by their respective package licenses. See `pubspec.yaml` and `pubspec.lock` for the dependency list.

Direct dependencies declared in `pubspec.yaml` include:

* Flutter SDK
* `shared_preferences`
* `intl`
* `google_fonts`
* `audioplayers`
* `flutter_svg`
* `font_awesome_flutter`

Development dependencies include:

* `flutter_test`
* `flutter_lints`
* `flutter_launcher_icons`

Package license details are available from the package metadata.

## AndroidX / Play Core / multidex

Android Gradle dependencies declared in `android/app/build.gradle.kts` include:

* `com.google.android.play:core`
* `androidx.multidex:multidex`

These Android support/build libraries are not ads, billing, analytics, login, or cloud-sync services.

## Branding

* Asset type: Turbo Chess launcher/app icon
* Local asset: `assets/branding/turbo_chess_launcher_icon.png`
* Launcher icon generation: `flutter_launcher_icons` configuration in `pubspec.yaml`

The launcher icon is treated as Turbo Chess project branding. No third-party endorsement is implied.
