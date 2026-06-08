# Sound Asset Audit

## Files inspected

* `assets/sounds/chess/`
* `assets/sounds/chess/LICENSES.md`
* `assets/sounds/chess/SOURCE.md`
* `assets/sounds/chess/VERIFICATION.md`
* `lib/core/audio/turbo_sound_service.dart`
* `pubspec.yaml`
* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`

## Bundled sound files

* `move.mp3`
* `capture.mp3`
* `check.mp3`
* `checkmate.mp3`

## Code references

`TurboSoundService.soundAssets` references:

* `sounds/chess/move.mp3`
* `sounds/chess/capture.mp3`
* `sounds/chess/check.mp3`
* `sounds/chess/checkmate.mp3`

## Findings

`pubspec.yaml` bundles `assets/sounds/chess/`.

Local source docs state that the files come from OpenGameArt "Click sounds(6)" by pauliuw under CC0.

Local source docs map each local MP3 to an original OpenGameArt MP3 file and state that the local files were renamed only.

No unknown extra sound files were found under `assets/sounds/chess/`.

Public notices match the local sound documentation.

## Maintainer notes

Maintainers should keep source and license documentation available if sound assets change.
