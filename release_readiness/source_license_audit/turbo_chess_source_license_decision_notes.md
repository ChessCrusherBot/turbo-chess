# Turbo Chess Source License Decision Notes

This file prepares the source-license decision. It is not legal advice and does not claim final GPL compliance is complete.

## Current Findings

* A root `LICENSE` file exists.
* The root `LICENSE` file contains the GNU General Public License version 3 text.
* Existing project notes say Turbo Chess is being prepared for a GPLv3/open-source release because the app bundles Stockfish.
* Stockfish is GPLv3.
* `assets/legal/TURBO_CHESS_SOURCE.md`, `docs/OPEN_SOURCE_RELEASE.md`, and `docs/SECRETS_AND_SIGNING.md` already discuss public source release and private signing-file safety.

## Decision Status

Turbo Chess app source licensing is still a release decision for the human owner. A GPLv3-compatible approach is likely safest because Stockfish is GPLv3 and is bundled with the Android app, but the final source-release plan should be reviewed before publishing or pushing to GitHub.

Do not invent final ownership/legal terms without human approval. Do not claim final Stockfish GPLv3/source availability compliance is complete until the final upload-time source availability plan is finished.

## Recommended Human Decision Before Public Source Release

* Confirm whether the Turbo Chess app source is intentionally released under GPLv3.
* Confirm copyright owner/name and contact information.
* Confirm whether any extra notices are needed beyond `LICENSE`, `THIRD_PARTY_NOTICES.md`, and `assets/legal/`.
* Confirm Stockfish source availability and build/source correspondence before Play Store upload.
