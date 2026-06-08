# Branding Ownership Check

## Files inspected

* `assets/branding/turbo_chess_launcher_icon.png`
* `pubspec.yaml`
* Android launcher icon resources under `android/app/src/main/res/`
* public notices

## Branding files found

* `assets/branding/turbo_chess_launcher_icon.png`
* Generated Android launcher/adaptive icon resources under `android/app/src/main/res/`

`pubspec.yaml` uses `flutter_launcher_icons` and points `image_path` and adaptive foreground to `assets/branding/turbo_chess_launcher_icon.png`.

## Findings

Public notices state that the launcher icon is treated as a Turbo Chess project branding asset and no third-party endorsement is implied.

No Chess.com, Lichess, or Stockfish logo asset file was found in the inspected app asset paths.

No third-party brand logo appears to be intentionally bundled as the app icon.

## Maintainer notes

Maintainers should keep a clear ownership record for the app icon and future branding assets.
