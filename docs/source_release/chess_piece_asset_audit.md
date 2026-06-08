# Chess Piece Asset Audit

## Files inspected

* `assets/pieces/cburnett_bsd/LICENSE.txt`
* `assets/pieces/cburnett_bsd/SOURCE.md`
* `assets/pieces/cburnett_bsd/VERIFICATION.md`
* `assets/pieces/cburnett_bsd/svg/`
* `pubspec.yaml`
* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`

## Bundled piece files

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

`pubspec.yaml` bundles `assets/pieces/cburnett_bsd/svg/`, `LICENSE.txt`, `SOURCE.md`, and `VERIFICATION.md`.

The local source file maps all 12 app SVG files to Wikimedia Commons Cburnett chess piece file pages and original-file URLs.

The local verification file records author/source as Cburnett / Own work, records the BSD license option, and records the selected BSD license choice.

No different or unknown chess piece set was found under `assets/pieces/`.

Public notices mention Cburnett SVG chess pieces, Wikimedia Commons, BSD license selection, and no endorsement.

## Maintainer notes

Maintainers should keep the online source links and local license files available if piece assets change.
