import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/ads/ad_shell.dart';

void main() {
  test(
      'app has no ad SDK dependency, identifiers, permissions, or runtime calls',
      () {
    final source = <String>[
      _read('pubspec.yaml'),
      _readIfExists('pubspec.lock'),
      _read('android/app/build.gradle.kts'),
      _read('android/app/src/main/AndroidManifest.xml'),
      _readIfExists('android/app/proguard-rules.pro'),
      _read('THIRD_PARTY_NOTICES.md'),
      _sourceTextUnder('lib'),
    ].join('\n');

    const forbidden = <String>[
      'google_mobile_ads',
      'ca-app-pub',
      'com.google.android.gms.ads',
      'admobApplicationId',
      'TURBO_CHESS_ENABLE_ADS',
      'TURBO_CHESS_ENABLE_REWARDED_ADS',
      'android.permission.INTERNET',
      'android.permission.ACCESS_NETWORK_STATE',
      'in_app_purchase',
      'billingclient',
      'Google Play Billing',
    ];

    for (final token in forbidden) {
      expect(source, isNot(contains(token)), reason: token);
    }

    final forbiddenSdkClasses = <RegExp>[
      RegExp(r'\bMobileAds\b'),
      RegExp(r'\bAdRequest\b'),
      RegExp(r'\bBannerAd\b'),
      RegExp(r'\bRewardedAd\b'),
      RegExp(r'\bInterstitialAd\b'),
      RegExp(r'\bAppOpenAd\b'),
      RegExp(r'\bLoadAdError\b'),
    ];

    for (final pattern in forbiddenSdkClasses) {
      expect(pattern.hasMatch(source), isFalse, reason: pattern.pattern);
    }
  });

  test('user-facing monetization text is absent from app source', () {
    final source = _sourceTextUnder('lib');

    const forbidden = <String>[
      '72-Hour Rewarded Pass',
      'Watch rewarded ad',
      'Rewarded Pass',
      'rewarded ad',
      'Ad-free pass',
      'Ads active',
      'Access Status',
      'Subscribe',
      'Restore Premium',
      'Manage subscription',
      'Complete the purchase',
      'subscription',
      'purchase',
      'billing',
    ];

    for (final token in forbidden) {
      expect(source, isNot(contains(token)), reason: token);
    }
  });

  test('legacy ad shell remains a no-op compatibility layer', () {
    expect(AdBannerPolicy.shouldShowBanners(screenVisible: true), isFalse);
    expect(AdBannerPolicy.shouldShowBanners(screenVisible: false), isFalse);
  });

  test('release package id remains stable', () {
    final gradle = _read('android/app/build.gradle.kts');
    final manifest = _read('android/app/src/main/AndroidManifest.xml');

    expect(gradle, contains('namespace = "com.turbochess.app"'));
    expect(gradle, contains('applicationId = "com.turbochess.app"'));
    expect(manifest, isNot(contains('turbo_chess_auth_callback')));
    expect(manifest, isNot(contains('android:host="auth"')));
  });

  test('More Legal shows plain GitHub source link without URL launcher', () {
    final moreSource = _read('lib/features/more/presentation/more_screen.dart');
    final pubspec = _read('pubspec.yaml');

    expect(moreSource, contains('Source code'));
    expect(
      moreSource,
      contains('https://github.com/ChessCrusherBot/turbo-chess'),
    );
    expect(moreSource, isNot(contains('url_launcher')));
    expect(pubspec, isNot(contains('url_launcher')));
  });

  test('third-party notices match current free app assets and dependencies',
      () {
    final notices = _read('THIRD_PARTY_NOTICES.md');
    final appNotices = _read('assets/legal/THIRD_PARTY_NOTICES.md');
    final combined = '$notices\n$appNotices';

    for (final token in const [
      'Stockfish',
      'GPLv3',
      'Cburnett',
      'OpenGameArt "Click sounds(6)"',
      'CC0',
      'Font Awesome Free',
      'google_fonts',
      'shared_preferences',
      'intl',
      'audioplayers',
      'flutter_svg',
      'font_awesome_flutter',
      'assets/branding/turbo_chess_launcher_icon.png',
      'Position/FEN Files',
      'Included in the app/source package:',
      'bundled FEN training positions derived from Lichess open database material',
      'offline chess practice',
      'does not use Lichess broadcast games',
      'com.google.android.play:core',
      'androidx.multidex:multidex',
    ]) {
      expect(combined, contains(token), reason: token);
    }

    for (final internalReminder in const [
      'pre-upload human/legal review item',
      'before Play Store upload',
      'before upload',
      'final review',
      'human/legal review',
      'record exact',
      'archives/months',
      'source availability review',
      'Project generation notes',
      'Current project notes',
      'local generation notes',
      'Local files:',
    ]) {
      expect(combined, isNot(contains(internalReminder)),
          reason: internalReminder);
    }

    for (final removed in const [
      'google_mobile_ads',
      'in_app_purchase',
      'url_launcher',
      'AdMob',
      'rewarded ads',
    ]) {
      expect(combined, isNot(contains(removed)), reason: removed);
    }
  });
}

String _sourceTextUnder(String relativePath) {
  final root = Directory(relativePath);
  final buffer = StringBuffer();
  for (final entity in root.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      buffer.writeln(entity.readAsStringSync());
    }
  }
  return buffer.toString();
}

String _read(String relativePath) => File(relativePath).readAsStringSync();

String _readIfExists(String relativePath) {
  final file = File(relativePath);
  return file.existsSync() ? file.readAsStringSync() : '';
}
