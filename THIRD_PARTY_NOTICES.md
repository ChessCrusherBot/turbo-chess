# Third-Party Notices

Turbo Chess is prepared for GPLv3/open-source release from an engineering perspective. This file summarizes bundled third-party code and assets. It is not legal advice or a legal guarantee.

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

## Font Awesome Free / font_awesome_flutter

- Asset type: Icon font/glyphs and Flutter package
- Font Awesome Free icons/fonts by Fonticons, Inc.
- `font_awesome_flutter` Flutter package by its contributors
- Font Awesome Free is distributed under its published free license terms, including CC BY 4.0 for SVG/JS icons, SIL OFL 1.1 for fonts, and MIT for code as applicable.
- `font_awesome_flutter` package license: MIT

Only Font Awesome Free icons are used. No Font Awesome Pro icons or private icon files are bundled.

## Flutter and Dart Dependencies

Flutter and Dart package dependencies are governed by their respective package licenses. See `pubspec.yaml` and `pubspec.lock` for the dependency list.

Direct dependencies currently declared in `pubspec.yaml` include:

- Flutter SDK
- `shared_preferences`
- `intl`
- `google_fonts`
- `audioplayers`
- `google_mobile_ads`
- `flutter_svg`
- `in_app_purchase`
- `url_launcher`
- `font_awesome_flutter`

Development dependencies include:

- `flutter_test`
- `flutter_lints`
- `flutter_launcher_icons`

Before a public source release, generate or review dependency license information from the package metadata if a formal dependency license report is required.

## Unknown or Follow-Up Licenses

No additional bundled third-party asset licenses were identified during this engineering pass. Re-run a dependency and asset license audit before each public release.
