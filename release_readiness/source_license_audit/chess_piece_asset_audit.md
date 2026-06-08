# Turbo Chess Chess Piece Asset Audit

## Files Inspected

* `assets/pieces/cburnett_bsd/LICENSE.txt`
* `assets/pieces/cburnett_bsd/SOURCE.md`
* `assets/pieces/cburnett_bsd/VERIFICATION.md`
* `assets/pieces/cburnett_bsd/svg/`
* `pubspec.yaml`
* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`
* app Legal text in `lib/features/more/presentation/more_screen.dart`

## Bundled Piece Files

* `wK.svg`
* `wQ.svg`
* `wR.svg`
* `wB.svg`
* `wN.svg`
* `wP.svg`
* `bK.svg`
* `bQ.svg`
* `bR.svg`
* `bB.svg`
* `bN.svg`
* `bP.svg`

## Findings

* `pubspec.yaml` bundles `assets/pieces/cburnett_bsd/svg/`, `LICENSE.txt`, `SOURCE.md`, and `VERIFICATION.md`.
* The local source file maps all 12 app SVG files to Wikimedia Commons Cburnett chess piece file pages and original-file URLs.
* The local verification file records author/source as Cburnett / Own work, says the BSD option was found, and says license choice is allowed.
* No different or unknown chess piece set was found under `assets/pieces/`.
* Public Legal text and third-party notices mention Cburnett SVG chess pieces, Wikimedia Commons, BSD license selection, and no endorsement.

## Remaining Human Check

The local documentation is strong. Exact online source should still be confirmed by a human before public source release.

No piece assets were changed.
