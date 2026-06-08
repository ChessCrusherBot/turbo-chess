# Turbo Chess Branding Ownership Check

## Files Inspected

* `assets/branding/turbo_chess_launcher_icon.png`
* `pubspec.yaml`
* Android launcher icon resources under `android/app/src/main/res/`
* app Legal text and third-party notices
* project search for third-party brand/logo terms

## Branding Files Found

* `assets/branding/turbo_chess_launcher_icon.png`
  * Dimensions: 2000 x 2000 px
  * Size: 846,713 bytes
* Generated Android launcher/adaptive icon resources under `android/app/src/main/res/`
* `pubspec.yaml` uses `flutter_launcher_icons` and points `image_path` and adaptive foreground to `assets/branding/turbo_chess_launcher_icon.png`.

## Findings

* Public Legal text and third-party notices say the launcher icon is treated as a Turbo Chess project branding asset and no third-party endorsement is implied.
* No Chess.com, Lichess, or Stockfish logo asset file was found in the app asset paths inspected.
* No third-party brand logo appears to be intentionally bundled as the app icon.

## Remaining Human Check

The project treats the app icon as Turbo Chess-owned branding, but exact design provenance is not independently documented in the inspected files. Human should confirm app icon ownership before Play Store upload.

No branding files were replaced in this task.
