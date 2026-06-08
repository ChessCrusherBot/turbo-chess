import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/ads/ad_free_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('version 1 access service stays inactive and blocks banners', () async {
    final service = AdFreeService.forTesting();

    await service.initialize();

    expect(service.isAdFree, isFalse);
    expect(service.isAdFreeActive(), isFalse);
    expect(service.getRemainingAdFreeDuration(), Duration.zero);
    expect(service.status.isAdFree, isFalse);
    expect(service.status.remainingDuration, Duration.zero);
    expect(service.status.shouldShowVerificationMessage, isFalse);
    expect(AdFreeAccessPolicy.isAdFree, isFalse);
    expect(AdFreeAccessPolicy.canShowBannerAds, isFalse);
  });

  test('initialization clears old local access state', () async {
    SharedPreferences.setMockInitialValues(_legacyAccessState());

    final service = AdFreeService.forTesting();
    await service.initialize();

    final prefs = await SharedPreferences.getInstance();
    for (final key in _legacyAccessState().keys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(service.isAdFree, isFalse);
    expect(service.status.remainingDuration, Duration.zero);
  });

  test('refresh keeps the app free and removes old state', () async {
    SharedPreferences.setMockInitialValues(_legacyAccessState());
    final service = AdFreeService.forTesting();

    await service.refreshAdFreeStatus();

    final prefs = await SharedPreferences.getInstance();
    for (final key in _legacyAccessState().keys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(service.isAdFreeActive(), isFalse);
    expect(AdFreeAccessPolicy.canShowBannerAds, isFalse);
  });
}

Map<String, Object> _legacyAccessState() => <String, Object>{
      'ads.reward_granted_at_utc': '2026-01-01T00:00:00.000Z',
      'ads.reward_expires_at_utc': '2026-01-04T00:00:00.000Z',
      'ads.last_verified_server_utc': '2026-01-01T00:00:00.000Z',
      'ads.last_seen_device_utc': '2026-01-01T00:00:00.000Z',
      'ads.last_seen_elapsed_realtime_ms': 1000,
      'ads.reward_pass_source': 'legacy',
      'ads.reward_pass_unverifiable': true,
    };
