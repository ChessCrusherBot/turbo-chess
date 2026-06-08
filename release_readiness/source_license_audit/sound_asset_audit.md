# Turbo Chess Sound Asset Audit

## Files Inspected

* `assets/sounds/chess/`
* `assets/sounds/chess/LICENSES.md`
* `assets/sounds/chess/SOURCE.md`
* `assets/sounds/chess/VERIFICATION.md`
* `lib/core/audio/turbo_sound_service.dart`
* `pubspec.yaml`
* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`
* app Legal text in `lib/features/more/presentation/more_screen.dart`

## Bundled Sound Files

* `move.mp3`
* `capture.mp3`
* `check.mp3`
* `checkmate.mp3`

## Code References

`TurboSoundService.soundAssets` references:

* `sounds/chess/move.mp3`
* `sounds/chess/capture.mp3`
* `sounds/chess/check.mp3`
* `sounds/chess/checkmate.mp3`

## Findings

* `pubspec.yaml` bundles `assets/sounds/chess/`.
* Local source docs say the files come from OpenGameArt "Click sounds(6)" by pauliuw under CC0.
* Local source docs map each local MP3 to an original OpenGameArt MP3 file and say the only modification was renaming.
* Local verification docs record CC0, commercial use allowed, modification allowed, and attribution not required.
* No unknown extra sound files were found under `assets/sounds/chess/`.
* Public Legal text and third-party notices match the local documentation.

## Remaining Human Check

The local documentation is strong. Exact online source should still be confirmed by a human before public source release.

No sound files were changed or deleted.
