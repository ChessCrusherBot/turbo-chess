# Turbo Chess Font, Icon, And Package Audit

## Font Awesome

Files inspected:

* `pubspec.yaml`
* `pubspec.lock`
* `lib/core/ui/turbo_chess_icons.dart`
* `THIRD_PARTY_NOTICES.md`
* `assets/legal/THIRD_PARTY_NOTICES.md`
* app Legal text in `lib/features/more/presentation/more_screen.dart`

Findings:

* `font_awesome_flutter` is declared as a direct dependency.
* The only app import found is `package:font_awesome_flutter/font_awesome_flutter.dart`.
* App icon usages found:
  * `FontAwesomeIcons.chessPawn`
  * `FontAwesomeIcons.chessKnight`
  * `FontAwesomeIcons.chessKing`
  * `FontAwesomeIcons.robot`
  * `FontAwesomeIcons.crown`
* No Font Awesome Pro package, Pro icon source, or private icon files were found.
* Public Legal text and third-party notices say Font Awesome Free is used and no Pro icons are bundled.

If any icon name is later changed, re-check whether it is available in Font Awesome Free.

## Google Fonts / Inter

Files inspected:

* `pubspec.yaml`
* `pubspec.lock`
* `lib/main.dart`
* `lib/app/theme.dart`
* app Legal text and third-party notices

Findings:

* `google_fonts` is declared as a direct dependency.
* `lib/main.dart` sets `GoogleFonts.config.allowRuntimeFetching = false`.
* `lib/app/theme.dart` uses Inter through `GoogleFonts.interTextTheme` and `GoogleFonts.inter`.
* The Android release app is expected to have no `INTERNET` permission.
* Public Legal text and third-party notices mention Google Fonts / Inter and runtime font fetching being disabled.

If exact Inter font file distribution needs to be proven for a public source release, the human should confirm it. Do not add uncertain font-source claims to the public app UI.

## Direct Flutter/Dart Package Notices

Direct dependencies declared in `pubspec.yaml`:

* Flutter SDK
* `shared_preferences`
* `intl`
* `google_fonts`
* `audioplayers`
* `flutter_svg`
* `font_awesome_flutter`

Development dependencies:

* `flutter_test`
* `flutter_lints`
* `flutter_launcher_icons`

Removed/absent dependencies:

* `google_mobile_ads` is absent from `pubspec.yaml` and `pubspec.lock`.
* `in_app_purchase` is absent from `pubspec.yaml` and `pubspec.lock`.
* `url_launcher` is absent from `pubspec.yaml` and `pubspec.lock`.
* Firebase Analytics and Crashlytics packages were not found.

Current public notices summarize direct package dependencies. A generated full dependency license report can be added later if the human wants a formal package-license appendix.
