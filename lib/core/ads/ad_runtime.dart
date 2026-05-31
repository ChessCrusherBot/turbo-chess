import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_flags.dart';
import '../services/connectivity_service.dart';
import 'premium_pass_duration.dart';

enum RewardedAdOutcome {
  earned,
  dismissed,
  unavailable,
  failedToLoad,
  failedToShow,
}

class RewardedAdResult {
  final RewardedAdOutcome outcome;
  final String message;

  const RewardedAdResult({
    required this.outcome,
    required this.message,
  });

  bool get isRewardEarned => outcome == RewardedAdOutcome.earned;
}

class AdRuntimeDevicePolicy {
  const AdRuntimeDevicePolicy._();

  static bool shouldUseConservativeLoadingForLowResources({
    required bool isLowRamDevice,
    int? memoryClassMb,
    int? availableMemoryMb,
  }) {
    if (isLowRamDevice) {
      return true;
    }
    if (memoryClassMb != null && memoryClassMb <= 128) {
      return true;
    }
    if (availableMemoryMb != null && availableMemoryMb <= 128) {
      return true;
    }
    return false;
  }
}

class AdRuntime {
  static const MethodChannel _deviceChannel =
      MethodChannel('com.turbochess.app/stockfish');
  static const String _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _androidTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _androidReleaseBannerAdUnitId =
      'ca-app-pub-8049412043190582/1240143630';
  static const String _androidReleaseRewardedAdUnitId =
      'ca-app-pub-8049412043190582/3766234626';

  static final AdRuntime instance = AdRuntime._internal();

  AdRuntime._internal();

  bool _initialized = false;
  bool _usesConservativeAdLoading = false;
  bool _deviceProfileChecked = false;
  Future<void>? _initializationFuture;
  Future<void>? _deviceProfileFuture;

  bool get isMobileAdsSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get canUseAds => AppFlags.adsEnabled && isMobileAdsSupported;

  bool get usesConservativeAdLoading => _usesConservativeAdLoading;

  Future<void> initialize() {
    if (!canUseAds || _initialized) {
      return Future.value();
    }
    final existingInitialization = _initializationFuture;
    if (existingInitialization != null) {
      return existingInitialization;
    }

    final initialization = _initializeSafely();
    _initializationFuture = initialization;
    return initialization;
  }

  Future<void> _initializeSafely() async {
    await _resolveDeviceProfile();
    if (!canUseAds) {
      _initializationFuture = null;
      return;
    }

    try {
      developer.log('MobileAds initialize requested', name: 'TurboChessAds');
      await MobileAds.instance.initialize();
      developer.log('MobileAds initialized', name: 'TurboChessAds');
      _initialized = true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Mobile Ads initialization failed: $error');
      }
      developer.log(
        'MobileAds initialization failed: $error',
        name: 'TurboChessAds',
      );
      _initializationFuture = null;
    }
  }

  Future<void> _resolveDeviceProfile() {
    if (_deviceProfileChecked ||
        !isMobileAdsSupported ||
        defaultTargetPlatform != TargetPlatform.android) {
      return Future.value();
    }
    return _deviceProfileFuture ??= _resolveAndroidDeviceProfile();
  }

  Future<void> _resolveAndroidDeviceProfile() async {
    try {
      final payload = await _deviceChannel.invokeMapMethod<String, dynamic>(
        'getDeviceProfile',
      );
      _usesConservativeAdLoading =
          AdRuntimeDevicePolicy.shouldUseConservativeLoadingForLowResources(
        isLowRamDevice: payload?['lowRamDevice'] == true,
        memoryClassMb: payload?['memoryClassMb'] as int?,
        availableMemoryMb: payload?['availableMemoryMb'] as int?,
      );
      if (_usesConservativeAdLoading) {
        developer.log(
          'Conservative ad loading active for low-resource Android profile',
          name: 'TurboChessAds',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Mobile Ads device check failed: $error');
      }
    } finally {
      _deviceProfileChecked = true;
      _deviceProfileFuture = null;
    }
  }

  String get bannerAdUnitId {
    final configuredId = defaultTargetPlatform == TargetPlatform.iOS
        ? const String.fromEnvironment('TURBO_CHESS_BANNER_AD_UNIT_IOS')
        : const String.fromEnvironment('TURBO_CHESS_BANNER_AD_UNIT_ANDROID');
    if (configuredId.trim().isNotEmpty) {
      return configuredId.trim();
    }
    if (defaultTargetPlatform == TargetPlatform.android && kReleaseMode) {
      return _androidReleaseBannerAdUnitId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestBannerAdUnitId
        : _androidTestBannerAdUnitId;
  }

  String get rewardedAdUnitId {
    final configuredId = defaultTargetPlatform == TargetPlatform.iOS
        ? const String.fromEnvironment('TURBO_CHESS_REWARDED_AD_UNIT_IOS')
        : const String.fromEnvironment('TURBO_CHESS_REWARDED_AD_UNIT_ANDROID');
    if (configuredId.trim().isNotEmpty) {
      return configuredId.trim();
    }
    if (defaultTargetPlatform == TargetPlatform.android && kReleaseMode) {
      return _androidReleaseRewardedAdUnitId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestRewardedAdUnitId
        : _androidTestRewardedAdUnitId;
  }

  BannerAd createBannerAd({
    required BannerAdListener listener,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    );
  }

  Future<RewardedAdResult> showRewardedAd() async {
    if (!canUseAds) {
      return const RewardedAdResult(
        outcome: RewardedAdOutcome.unavailable,
        message: 'Ad not available. Please try again later.',
      );
    }

    await ConnectivityService().check();
    if (!ConnectivityService().isOnline) {
      return const RewardedAdResult(
        outcome: RewardedAdOutcome.unavailable,
        message: 'Ad not available. Please try again later.',
      );
    }

    await initialize();
    if (!canUseAds) {
      return const RewardedAdResult(
        outcome: RewardedAdOutcome.unavailable,
        message: 'Ad not available. Please try again later.',
      );
    }

    final completer = Completer<RewardedAdResult>();

    unawaited(
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            var rewardEarned = false;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!completer.isCompleted) {
                  completer.complete(
                    const RewardedAdResult(
                      outcome: RewardedAdOutcome.dismissed,
                      message: 'Premium Pass was not activated.',
                    ),
                  );
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                if (!completer.isCompleted) {
                  completer.complete(
                    const RewardedAdResult(
                      outcome: RewardedAdOutcome.failedToShow,
                      message: 'Ad not available. Please try again later.',
                    ),
                  );
                }
              },
            );

            ad.setImmersiveMode(true);
            unawaited(
              ad.show(
                onUserEarnedReward: (_, __) {
                  rewardEarned = true;
                  if (!completer.isCompleted) {
                    completer.complete(
                      const RewardedAdResult(
                        outcome: RewardedAdOutcome.earned,
                        message: rewardedPremiumPassActivatedMessage,
                      ),
                    );
                  }
                },
              ).catchError((Object _) {
                ad.dispose();
                if (!completer.isCompleted) {
                  completer.complete(
                    const RewardedAdResult(
                      outcome: RewardedAdOutcome.failedToShow,
                      message: 'Ad not available. Please try again later.',
                    ),
                  );
                }
              }),
            );

            if (rewardEarned && !completer.isCompleted) {
              completer.complete(
                const RewardedAdResult(
                  outcome: RewardedAdOutcome.earned,
                  message: rewardedPremiumPassActivatedMessage,
                ),
              );
            }
          },
          onAdFailedToLoad: (_) {
            if (!completer.isCompleted) {
              completer.complete(
                const RewardedAdResult(
                  outcome: RewardedAdOutcome.failedToLoad,
                  message: 'Ad not available. Please try again later.',
                ),
              );
            }
          },
        ),
      ).catchError((Object _) {
        if (!completer.isCompleted) {
          completer.complete(
            const RewardedAdResult(
              outcome: RewardedAdOutcome.failedToLoad,
              message: 'Ad not available. Please try again later.',
            ),
          );
        }
      }),
    );

    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => const RewardedAdResult(
        outcome: RewardedAdOutcome.failedToShow,
        message: 'Ad not available. Please try again later.',
      ),
    );
  }
}
