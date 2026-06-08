import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AdFreeSource {
  none,
}

class AdFreeAccessPolicy {
  const AdFreeAccessPolicy._();

  static bool get isAdFree => false;

  static bool get canShowBannerAds => false;
}

class AdFreeStatus {
  const AdFreeStatus.inactive();

  bool get isAdFree => false;

  AdFreeSource get activeSource => AdFreeSource.none;

  Duration get remainingDuration => Duration.zero;

  bool get shouldShowVerificationMessage => false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdFreeStatus;
  }

  @override
  int get hashCode => 0;
}

class AdFreeService extends ChangeNotifier {
  static const List<String> _legacyMonetizationKeys = [
    'ads.reward_granted_at_utc',
    'ads.reward_expires_at_utc',
    'ads.last_verified_server_utc',
    'ads.last_seen_device_utc',
    'ads.last_seen_elapsed_realtime_ms',
    'ads.reward_pass_source',
    'ads.reward_pass_unverifiable',
  ];

  static final AdFreeService instance = AdFreeService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;
  AdFreeStatus _status = const AdFreeStatus.inactive();

  AdFreeService._internal();

  @visibleForTesting
  AdFreeService.forTesting({Object? clock});

  AdFreeStatus get status => _status;

  bool get isInitialized => _initialized;

  bool get isAdFree => false;

  bool isAdFreeActive() => false;

  Duration getRemainingAdFreeDuration() => Duration.zero;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    await clearLegacyMonetizationState();
  }

  Future<void> refreshAdFreeStatus() async {
    await clearLegacyMonetizationState();
  }

  Future<void> clearLegacyMonetizationState() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    for (final key in _legacyMonetizationKeys) {
      await prefs.remove(key);
    }
    if (_status != const AdFreeStatus.inactive()) {
      _status = const AdFreeStatus.inactive();
      notifyListeners();
    }
  }
}
