# Font, Icon, and Package Audit

## Font Awesome Free

Files inspected:

* `pubspec.yaml`
* `pubspec.lock`
* `lib/core/ui/turbo_chess_icons.dart`
* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`

Findings:

* `font_awesome_flutter` is declared as a direct dependency.
* The app imports `package:font_awesome_flutter/font_awesome_flutter.dart`.
* App icon usages include chess pawn, chess knight, chess king, robot, and crown icons.
* No Font Awesome Pro package, Pro icon source, or private icon files were found.
* Public notices state that Font Awesome Free is used and no Pro icons are bundled.

## Google Fonts / Inter

Files inspected:

* `pubspec.yaml`
* `pubspec.lock`
* `lib/main.dart`
* `lib/app/theme.dart`
* app legal text and third-party notices

Findings:

* `google_fonts` is declared as a direct dependency.
* `lib/main.dart` sets `GoogleFonts.config.allowRuntimeFetching = false`.
* `lib/app/theme.dart` uses Inter through `GoogleFonts.interTextTheme` and `GoogleFonts.inter`.
* Public notices mention Google Fonts / Inter and runtime font fetching being disabled.
* The Android release app does not request the `INTERNET` permission.

## Direct Flutter/Dart packages

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

Removed or absent dependencies:

* `google_mobile_ads` is absent from `pubspec.yaml` and `pubspec.lock`.
* `in_app_purchase` is absent from `pubspec.yaml` and `pubspec.lock`.
* `url_launcher` is absent from `pubspec.yaml` and `pubspec.lock`.
* Firebase Analytics and Crashlytics packages were not found.

## Maintainer notes

Maintainers should update this audit and public notices when direct dependencies or icon/font usage changes.
