import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'entitlement_clock.dart';
import 'premium_pass_duration.dart';

class AdFreeProducts {
  static const String subscriptionProductId = 'turbo_chess_ad_free';
  static const String subscriptionBasePlanId = 'ad_free_4_weeks';
  static const String androidPackageId = 'com.turbochess.app';

  const AdFreeProducts._();
}

abstract class AdFreeBillingClient {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});

  Future<List<PurchaseDetails>> restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase);
}

class InAppPurchaseAdFreeBillingClient implements AdFreeBillingClient {
  final InAppPurchase _inAppPurchase;

  InAppPurchaseAdFreeBillingClient({
    InAppPurchase? inAppPurchase,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _inAppPurchase.purchaseStream;

  @override
  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) {
    return _inAppPurchase.queryProductDetails(identifiers);
  }

  @override
  Future<bool> buyNonConsumable({
    required PurchaseParam purchaseParam,
  }) {
    return _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<List<PurchaseDetails>> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
    return const <PurchaseDetails>[];
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _inAppPurchase.completePurchase(purchase);
  }
}

enum AdFreeSource {
  none,
  rewardedPass,
  subscription,
}

enum PremiumRestoreStatus {
  restored,
  notFound,
  productUnavailable,
  billingUnavailable,
  pending,
  error,
}

class PremiumRestoreResult {
  final PremiumRestoreStatus status;
  final String message;

  const PremiumRestoreResult({
    required this.status,
    required this.message,
  });

  bool get restored => status == PremiumRestoreStatus.restored;
}

class PremiumSubscriptionCopy {
  static const String accountNoticeLine1 =
      'Premium is linked to your Google Account.';

  static const String accountNoticeLine2 =
      'Use Restore Premium to recover access on another Android device.';

  static const String accountNoticeLine3 =
      'Turbo Chess does not create a separate app account.';

  static const String accountNotice =
      '$accountNoticeLine1 $accountNoticeLine2 $accountNoticeLine3';

  static const String accountNoticeLong =
      'Turbo Chess Premium is purchased through Google Play. Your subscription is linked to the Google Account used at checkout, not to a Turbo Chess login. To use or restore Premium on another Android device, install Turbo Chess with the same Google Account and tap Restore Premium.';

  static const String restoredMessage =
      'Premium restored. Your Google Play subscription is active.';

  static const String activeMessage =
      'Your Google Play subscription is active.';

  static const String billingUnavailableMessage =
      'Google Play Billing is unavailable right now. Please try again later.';

  static const String productUnavailableMessage =
      'Turbo Chess Premium is unavailable in Google Play right now. Please try again later.';

  static const String pendingMessage =
      'Purchase is pending. Premium will activate when Google Play confirms the purchase.';

  static const String restoreNotFoundShortMessage =
      'No active Premium subscription found. Make sure Google Play is using the same Google Account used to buy Turbo Chess Premium.';

  static const String restoreTroubleshootingMessage = '''
No active Premium subscription found.

Please check:
1. Open Google Play Store.
2. Tap the profile icon.
3. Make sure you are using the same Google Account used to buy Turbo Chess Premium.
4. Go to Payments & subscriptions > Subscriptions.
5. Confirm Turbo Chess Premium is active.
6. Return to Turbo Chess and tap Restore Premium again.

Turbo Chess cannot restore purchases made with a different Google Account.''';

  const PremiumSubscriptionCopy._();
}

class AdFreeStatus {
  final bool hasRewardedPass;
  final bool hasStoredRewardedPass;
  final bool hasActiveSubscription;
  final bool isRewardedPassUnverifiable;
  final DateTime? rewardedPassGrantedAt;
  final DateTime? rewardedPassExpiresAt;
  final DateTime? lastVerifiedServerUtc;
  final DateTime? lastSeenDeviceUtc;
  final bool isSubscriptionVerifying;
  final bool isSubscriptionStoreAvailable;
  final bool isSubscriptionPurchasePending;
  final ProductDetails? subscriptionProductDetails;
  final String? subscriptionMessage;
  final String? subscriptionError;

  const AdFreeStatus({
    required this.hasRewardedPass,
    required this.hasStoredRewardedPass,
    required this.hasActiveSubscription,
    required this.isRewardedPassUnverifiable,
    this.rewardedPassGrantedAt,
    this.rewardedPassExpiresAt,
    this.lastVerifiedServerUtc,
    this.lastSeenDeviceUtc,
    required this.isSubscriptionVerifying,
    required this.isSubscriptionStoreAvailable,
    required this.isSubscriptionPurchasePending,
    this.subscriptionProductDetails,
    this.subscriptionMessage,
    this.subscriptionError,
  });

  const AdFreeStatus.inactive()
      : hasRewardedPass = false,
        hasStoredRewardedPass = false,
        hasActiveSubscription = false,
        isRewardedPassUnverifiable = false,
        rewardedPassGrantedAt = null,
        rewardedPassExpiresAt = null,
        lastVerifiedServerUtc = null,
        lastSeenDeviceUtc = null,
        isSubscriptionVerifying = false,
        isSubscriptionStoreAvailable = false,
        isSubscriptionPurchasePending = false,
        subscriptionProductDetails = null,
        subscriptionMessage = null,
        subscriptionError = null;

  bool get isAdFree => hasActiveSubscription || hasRewardedPass;

  bool get isSubscriptionProductAvailable => subscriptionProductDetails != null;

  DateTime? get adFreeUntil => rewardedPassExpiresAt;

  AdFreeSource get activeSource {
    if (hasActiveSubscription) {
      return AdFreeSource.subscription;
    }
    if (hasRewardedPass) {
      return AdFreeSource.rewardedPass;
    }
    return AdFreeSource.none;
  }

  Duration get remainingDuration {
    if (!hasRewardedPass || rewardedPassExpiresAt == null) {
      return Duration.zero;
    }
    final remaining = rewardedPassExpiresAt!.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get shouldShowVerificationMessage {
    return hasStoredRewardedPass && isRewardedPassUnverifiable;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdFreeStatus &&
        other.hasRewardedPass == hasRewardedPass &&
        other.hasStoredRewardedPass == hasStoredRewardedPass &&
        other.hasActiveSubscription == hasActiveSubscription &&
        other.isRewardedPassUnverifiable == isRewardedPassUnverifiable &&
        other.rewardedPassGrantedAt == rewardedPassGrantedAt &&
        other.rewardedPassExpiresAt == rewardedPassExpiresAt &&
        other.lastVerifiedServerUtc == lastVerifiedServerUtc &&
        other.lastSeenDeviceUtc == lastSeenDeviceUtc &&
        other.isSubscriptionVerifying == isSubscriptionVerifying &&
        other.isSubscriptionStoreAvailable == isSubscriptionStoreAvailable &&
        other.isSubscriptionPurchasePending == isSubscriptionPurchasePending &&
        other.subscriptionProductDetails == subscriptionProductDetails &&
        other.subscriptionMessage == subscriptionMessage &&
        other.subscriptionError == subscriptionError;
  }

  @override
  int get hashCode => Object.hash(
        hasRewardedPass,
        hasStoredRewardedPass,
        hasActiveSubscription,
        isRewardedPassUnverifiable,
        rewardedPassGrantedAt,
        rewardedPassExpiresAt,
        lastVerifiedServerUtc,
        lastSeenDeviceUtc,
        isSubscriptionVerifying,
        isSubscriptionStoreAvailable,
        isSubscriptionPurchasePending,
        subscriptionProductDetails,
        subscriptionMessage,
        subscriptionError,
      );
}

class AdFreeService extends ChangeNotifier with WidgetsBindingObserver {
  static const String _rewardGrantedAtUtcKey = 'ads.reward_granted_at_utc';
  static const String _rewardExpiresAtUtcKey = 'ads.reward_expires_at_utc';
  static const String _lastVerifiedServerUtcKey =
      'ads.last_verified_server_utc';
  static const String _lastSeenDeviceUtcKey = 'ads.last_seen_device_utc';
  static const String _lastSeenElapsedRealtimeKey =
      'ads.last_seen_elapsed_realtime_ms';
  static const String _rewardPassSourceKey = 'ads.reward_pass_source';
  static const String _rewardPassUnverifiableKey =
      'ads.reward_pass_unverifiable';
  static const Duration _rewardedPassDuration = rewardedPremiumPassDuration;
  static const Duration _clockRollbackThreshold = Duration(minutes: 5);

  static final AdFreeService instance = AdFreeService._internal();

  final EntitlementClock _clock;
  final AdFreeBillingClient _billingClient;
  final bool _observeLifecycle;
  final bool _scheduleTimers;
  final Duration _restorePurchaseUpdateTimeout;

  SharedPreferences? _prefs;
  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdates;
  Completer<List<PurchaseDetails>>? _restoreUpdatesCompleter;
  Timer? _expiryTimer;
  bool _initialized = false;

  bool _hasRewardedPass = false;
  bool _hasStoredRewardedPass = false;
  bool _isRewardedPassUnverifiable = false;
  DateTime? _rewardedPassGrantedAt;
  DateTime? _rewardedPassExpiresAt;
  DateTime? _lastVerifiedServerUtc;
  DateTime? _lastSeenDeviceUtc;

  bool _hasActiveSubscription = false;
  bool _isSubscriptionVerifying = false;
  bool _isSubscriptionStoreAvailable = false;
  bool _isSubscriptionPurchasePending = false;
  ProductDetails? _subscriptionProductDetails;
  String? _subscriptionMessage;
  String? _subscriptionError;

  AdFreeStatus _status = const AdFreeStatus.inactive();

  AdFreeService._internal()
      : _clock = const DeviceEntitlementClock(),
        _billingClient = InAppPurchaseAdFreeBillingClient(),
        _observeLifecycle = true,
        _scheduleTimers = true,
        _restorePurchaseUpdateTimeout = const Duration(milliseconds: 1200);

  @visibleForTesting
  AdFreeService.forTesting({
    required EntitlementClock clock,
    required AdFreeBillingClient billingClient,
    Duration restorePurchaseUpdateTimeout = const Duration(milliseconds: 50),
  })  : _clock = clock,
        _billingClient = billingClient,
        _observeLifecycle = false,
        _scheduleTimers = false,
        _restorePurchaseUpdateTimeout = restorePurchaseUpdateTimeout;

  AdFreeStatus get status => _status;

  bool get isInitialized => _initialized;

  bool get isAdFree => _status.isAdFree;

  bool get hasRewardedPass => _status.hasRewardedPass;

  bool get hasActiveSubscription => _status.hasActiveSubscription;

  DateTime? get rewardedPassExpiresAt => _status.rewardedPassExpiresAt;

  bool isAdFreeActive() => isAdFree;

  Duration getRemainingAdFreeDuration() => _status.remainingDuration;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    _purchaseUpdates = _billingClient.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchaseUpdates(purchases)),
      onError: (Object error) {
        _hasActiveSubscription = false;
        _isSubscriptionPurchasePending = false;
        _subscriptionError =
            'Subscription status could not be verified. Please try again later.';
        _publishStatus();
      },
    );
    if (_observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
    _initialized = true;
    await refreshAdFreeStatus();
    await refreshSubscriptionEntitlement();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) {
      return _prefs!;
    }
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> grantRewardedAdFreePass({
    String lastPassSource = 'rewarded_ad',
  }) async {
    final prefs = await _ensurePrefs();
    final snapshot = await _clock.snapshot();
    final grantedAt = snapshot.bestAvailableUtc.toUtc();
    final existingExpiry =
        _parseUtc(prefs.getString(_rewardExpiresAtUtcKey))?.toUtc();
    final extensionBase =
        existingExpiry != null && existingExpiry.isAfter(grantedAt)
            ? existingExpiry
            : grantedAt;
    final expiresAt = extensionBase.add(_rewardedPassDuration);

    await prefs.setString(
      _rewardGrantedAtUtcKey,
      grantedAt.toIso8601String(),
    );
    await prefs.setString(
      _rewardExpiresAtUtcKey,
      expiresAt.toIso8601String(),
    );
    await prefs.setString(_rewardPassSourceKey, lastPassSource);
    await prefs.setBool(_rewardPassUnverifiableKey, false);
    if (snapshot.verifiedServerUtc != null) {
      await prefs.setString(
        _lastVerifiedServerUtcKey,
        snapshot.verifiedServerUtc!.toUtc().toIso8601String(),
      );
    }
    await _recordLastSeen(snapshot);
    await refreshAdFreeStatus();
  }

  Future<void> clearExpiredAdFreePass() async {
    final prefs = await _ensurePrefs();
    _expiryTimer?.cancel();
    await prefs.remove(_rewardExpiresAtUtcKey);
    await prefs.remove(_rewardGrantedAtUtcKey);
    await prefs.remove(_rewardPassSourceKey);
    await prefs.remove(_rewardPassUnverifiableKey);
    _hasRewardedPass = false;
    _hasStoredRewardedPass = false;
    _isRewardedPassUnverifiable = false;
    _rewardedPassExpiresAt = null;
    _rewardedPassGrantedAt = null;
    _publishStatus();
  }

  Future<void> refreshAdFreeStatus() async {
    await _refreshRewardedPassStatus();
    _publishStatus();
  }

  Future<void> refreshSubscriptionEntitlement() async {
    await _refreshSubscriptionEntitlement(
      waitForPurchaseUpdates: false,
      showNotFoundMessage: false,
    );
  }

  Future<PremiumRestoreResult> restorePremium({
    bool showNotFoundMessage = true,
  }) {
    return _refreshSubscriptionEntitlement(
      waitForPurchaseUpdates: true,
      showNotFoundMessage: showNotFoundMessage,
    );
  }

  Future<PremiumRestoreResult> _refreshSubscriptionEntitlement({
    required bool waitForPurchaseUpdates,
    required bool showNotFoundMessage,
  }) async {
    _isSubscriptionVerifying = true;
    _isSubscriptionPurchasePending = false;
    _subscriptionError = null;
    _subscriptionMessage = 'Checking Google Play subscription status...';
    _hasActiveSubscription = false;
    _publishStatus();

    try {
      final isAvailable = await _billingClient.isAvailable();
      _isSubscriptionStoreAvailable = isAvailable;

      if (!isAvailable) {
        _isSubscriptionVerifying = false;
        _subscriptionMessage =
            PremiumSubscriptionCopy.billingUnavailableMessage;
        _publishStatus();
        return const PremiumRestoreResult(
          status: PremiumRestoreStatus.billingUnavailable,
          message: PremiumSubscriptionCopy.billingUnavailableMessage,
        );
      }

      await _loadSubscriptionProductDetails();
      final productAvailable = _subscriptionProductDetails != null;
      final restoredPurchases = await _restorePurchases(
        waitForPurchaseUpdates: waitForPurchaseUpdates,
      );
      if (restoredPurchases.isNotEmpty) {
        await _handlePurchaseUpdates(restoredPurchases);
      }

      _isSubscriptionVerifying = false;
      if (_hasActiveSubscription) {
        _subscriptionMessage = showNotFoundMessage
            ? PremiumSubscriptionCopy.restoredMessage
            : PremiumSubscriptionCopy.activeMessage;
        _subscriptionError = null;
        _publishStatus();
        return PremiumRestoreResult(
          status: PremiumRestoreStatus.restored,
          message: _subscriptionMessage!,
        );
      }

      if (_isSubscriptionPurchasePending) {
        _subscriptionMessage = PremiumSubscriptionCopy.pendingMessage;
        _subscriptionError = null;
        _publishStatus();
        return const PremiumRestoreResult(
          status: PremiumRestoreStatus.pending,
          message: PremiumSubscriptionCopy.pendingMessage,
        );
      }

      if (!productAvailable) {
        _subscriptionMessage =
            PremiumSubscriptionCopy.productUnavailableMessage;
        _subscriptionError = null;
        _publishStatus();
        return const PremiumRestoreResult(
          status: PremiumRestoreStatus.productUnavailable,
          message: PremiumSubscriptionCopy.productUnavailableMessage,
        );
      }

      _subscriptionMessage = showNotFoundMessage
          ? PremiumSubscriptionCopy.restoreNotFoundShortMessage
          : null;
      _subscriptionError = null;
      _publishStatus();
      return PremiumRestoreResult(
        status: PremiumRestoreStatus.notFound,
        message: showNotFoundMessage
            ? PremiumSubscriptionCopy.restoreTroubleshootingMessage
            : PremiumSubscriptionCopy.restoreNotFoundShortMessage,
      );
    } catch (_) {
      _hasActiveSubscription = false;
      _isSubscriptionVerifying = false;
      _isSubscriptionPurchasePending = false;
      _subscriptionError =
          'Subscription status could not be verified. Please try again later.';
      _publishStatus();
      return PremiumRestoreResult(
        status: PremiumRestoreStatus.error,
        message: _subscriptionError!,
      );
    }
  }

  Future<void> subscribeAdFree() async {
    if (_isSubscriptionPurchasePending) {
      return;
    }

    _subscriptionError = null;
    _subscriptionMessage = null;

    final restoreResult = await restorePremium(showNotFoundMessage: false);
    if (restoreResult.status == PremiumRestoreStatus.restored ||
        restoreResult.status == PremiumRestoreStatus.pending) {
      return;
    }
    if (restoreResult.status != PremiumRestoreStatus.notFound) {
      return;
    }

    final productDetails = _subscriptionProductDetails;
    if (productDetails == null) {
      _subscriptionMessage = PremiumSubscriptionCopy.productUnavailableMessage;
      _publishStatus();
      return;
    }

    _isSubscriptionPurchasePending = true;
    _subscriptionMessage = 'Complete the purchase in Google Play.';
    _publishStatus();

    final started = await _billingClient.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: productDetails),
    );
    if (!started) {
      _isSubscriptionPurchasePending = false;
      _subscriptionError =
          'The purchase could not be started. Please try again later.';
      _publishStatus();
    }
  }

  Future<bool> openManageSubscription() async {
    final url = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?sku=${AdFreeProducts.subscriptionProductId}'
      '&package=${AdFreeProducts.androidPackageId}',
    );

    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<List<PurchaseDetails>> _restorePurchases({
    required bool waitForPurchaseUpdates,
  }) async {
    if (!waitForPurchaseUpdates) {
      return _billingClient.restorePurchases();
    }

    final completer = Completer<List<PurchaseDetails>>();
    _restoreUpdatesCompleter = completer;
    try {
      final directPurchases = await _billingClient.restorePurchases();
      if (directPurchases.isNotEmpty) {
        return directPurchases;
      }
      await completer.future.timeout(
        _restorePurchaseUpdateTimeout,
        onTimeout: () => const <PurchaseDetails>[],
      );
      return const <PurchaseDetails>[];
    } finally {
      if (identical(_restoreUpdatesCompleter, completer)) {
        _restoreUpdatesCompleter = null;
      }
    }
  }

  Future<void> _loadSubscriptionProductDetails() async {
    try {
      final response = await _billingClient.queryProductDetails(
        const <String>{AdFreeProducts.subscriptionProductId},
      );
      _subscriptionProductDetails = _findProduct(
        response.productDetails,
        AdFreeProducts.subscriptionProductId,
      );
      if (response.error != null || _subscriptionProductDetails == null) {
        _subscriptionMessage =
            PremiumSubscriptionCopy.productUnavailableMessage;
      } else {
        _subscriptionMessage = null;
      }
    } catch (_) {
      _subscriptionProductDetails = null;
      _subscriptionMessage = PremiumSubscriptionCopy.productUnavailableMessage;
    }
    _publishStatus();
  }

  ProductDetails? _findProduct(List<ProductDetails> products, String id) {
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    final restoreCompleter = _restoreUpdatesCompleter;
    if (restoreCompleter != null && !restoreCompleter.isCompleted) {
      restoreCompleter.complete(List<PurchaseDetails>.of(purchases));
    }

    var touchedSubscription = false;

    for (final purchase in purchases) {
      if (purchase.productID != AdFreeProducts.subscriptionProductId) {
        continue;
      }

      touchedSubscription = true;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _hasActiveSubscription = false;
          _isSubscriptionPurchasePending = true;
          _subscriptionMessage = PremiumSubscriptionCopy.pendingMessage;
          _subscriptionError = null;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_isValidSubscriptionPurchase(purchase)) {
            _hasActiveSubscription = true;
            _isSubscriptionPurchasePending = false;
            _subscriptionMessage = PremiumSubscriptionCopy.activeMessage;
            _subscriptionError = null;
          } else {
            _hasActiveSubscription = false;
            _isSubscriptionPurchasePending = false;
            _subscriptionError =
                'Subscription status could not be verified. Please try again later.';
          }
          break;
        case PurchaseStatus.error:
          _hasActiveSubscription = false;
          _isSubscriptionPurchasePending = false;
          _subscriptionError =
              purchase.error?.message ?? 'Purchase could not be completed.';
          break;
        case PurchaseStatus.canceled:
          _hasActiveSubscription = false;
          _isSubscriptionPurchasePending = false;
          _subscriptionMessage = 'Purchase canceled.';
          _subscriptionError = null;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _billingClient.completePurchase(purchase);
      }
    }

    if (touchedSubscription) {
      _isSubscriptionVerifying = false;
      _publishStatus();
    }
  }

  bool _isValidSubscriptionPurchase(PurchaseDetails purchase) {
    return purchase.productID == AdFreeProducts.subscriptionProductId &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored);
  }

  Future<void> _refreshRewardedPassStatus() async {
    final prefs = await _ensurePrefs();
    final snapshot = await _clock.snapshot();
    final now = snapshot.bestAvailableUtc.toUtc();

    final expiresAt = _parseUtc(prefs.getString(_rewardExpiresAtUtcKey));
    final grantedAt = _parseUtc(prefs.getString(_rewardGrantedAtUtcKey));
    final lastSeenDeviceUtc = _parseUtc(prefs.getString(_lastSeenDeviceUtcKey));
    final lastVerifiedServerUtc =
        _parseUtc(prefs.getString(_lastVerifiedServerUtcKey));
    final lastSeenElapsed = prefs.getInt(_lastSeenElapsedRealtimeKey);
    final detectedRollback = _detectClockRollback(
      snapshot: snapshot,
      lastSeenDeviceUtc: lastSeenDeviceUtc,
      lastSeenElapsedRealtimeMillis: lastSeenElapsed,
    );
    final hasVerifiedServerTime = snapshot.hasVerifiedServerTime;

    _lastVerifiedServerUtc =
        snapshot.verifiedServerUtc?.toUtc() ?? lastVerifiedServerUtc?.toUtc();
    _lastSeenDeviceUtc = lastSeenDeviceUtc?.toUtc();
    _rewardedPassGrantedAt = grantedAt;
    _rewardedPassExpiresAt = expiresAt;

    if (expiresAt == null || grantedAt == null) {
      _expiryTimer?.cancel();
      _hasRewardedPass = false;
      _hasStoredRewardedPass = false;
      _isRewardedPassUnverifiable = false;
      await _recordLastSeen(snapshot, allowRollbackWrite: !detectedRollback);
      return;
    }

    _hasStoredRewardedPass = expiresAt.isAfter(now);

    if (!_hasStoredRewardedPass) {
      _expiryTimer?.cancel();
      _hasRewardedPass = false;
      _isRewardedPassUnverifiable = false;
      await _recordLastSeen(snapshot, allowRollbackWrite: !detectedRollback);
      return;
    }

    if (detectedRollback && !hasVerifiedServerTime) {
      _hasRewardedPass = false;
      _isRewardedPassUnverifiable = true;
      await prefs.setBool(_rewardPassUnverifiableKey, true);
      return;
    }

    _hasRewardedPass = true;
    _isRewardedPassUnverifiable = false;
    await prefs.setBool(_rewardPassUnverifiableKey, false);
    if (snapshot.verifiedServerUtc != null) {
      await prefs.setString(
        _lastVerifiedServerUtcKey,
        snapshot.verifiedServerUtc!.toUtc().toIso8601String(),
      );
    }
    await _recordLastSeen(snapshot);
    _scheduleRewardExpiry(expiresAt);
  }

  bool _detectClockRollback({
    required EntitlementTimeSnapshot snapshot,
    required DateTime? lastSeenDeviceUtc,
    required int? lastSeenElapsedRealtimeMillis,
  }) {
    final previousDeviceUtc = lastSeenDeviceUtc?.toUtc();
    if (previousDeviceUtc == null) {
      return false;
    }

    final currentDeviceUtc = snapshot.deviceUtc.toUtc();
    if (currentDeviceUtc.isBefore(
      previousDeviceUtc.subtract(_clockRollbackThreshold),
    )) {
      return true;
    }

    final previousElapsed = lastSeenElapsedRealtimeMillis;
    final currentElapsed = snapshot.elapsedRealtimeMillis;
    if (previousElapsed == null ||
        currentElapsed == null ||
        currentElapsed < previousElapsed) {
      return false;
    }

    final elapsedDelta =
        Duration(milliseconds: currentElapsed - previousElapsed);
    final expectedDeviceUtc = previousDeviceUtc.add(elapsedDelta);
    return currentDeviceUtc.isBefore(
      expectedDeviceUtc.subtract(_clockRollbackThreshold),
    );
  }

  Future<void> _recordLastSeen(
    EntitlementTimeSnapshot snapshot, {
    bool allowRollbackWrite = true,
  }) async {
    if (!allowRollbackWrite) {
      return;
    }

    final prefs = await _ensurePrefs();
    await prefs.setString(
      _lastSeenDeviceUtcKey,
      snapshot.deviceUtc.toUtc().toIso8601String(),
    );
    final elapsedRealtimeMillis = snapshot.elapsedRealtimeMillis;
    if (elapsedRealtimeMillis != null) {
      await prefs.setInt(_lastSeenElapsedRealtimeKey, elapsedRealtimeMillis);
    }
    _lastSeenDeviceUtc = snapshot.deviceUtc.toUtc();
  }

  DateTime? _parseUtc(String? raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  void _scheduleRewardExpiry(DateTime rewardedPassExpiresAt) {
    _expiryTimer?.cancel();
    if (!_scheduleTimers) {
      return;
    }
    final remaining = rewardedPassExpiresAt.difference(DateTime.now().toUtc());
    if (remaining.isNegative || remaining == Duration.zero) {
      unawaited(refreshAdFreeStatus());
      return;
    }
    _expiryTimer = Timer(remaining, () {
      unawaited(refreshAdFreeStatus());
    });
  }

  void _publishStatus() {
    _updateStatus(
      AdFreeStatus(
        hasRewardedPass: _hasRewardedPass,
        hasStoredRewardedPass: _hasStoredRewardedPass,
        hasActiveSubscription: _hasActiveSubscription,
        isRewardedPassUnverifiable: _isRewardedPassUnverifiable,
        rewardedPassGrantedAt: _rewardedPassGrantedAt,
        rewardedPassExpiresAt: _rewardedPassExpiresAt,
        lastVerifiedServerUtc: _lastVerifiedServerUtc,
        lastSeenDeviceUtc: _lastSeenDeviceUtc,
        isSubscriptionVerifying: _isSubscriptionVerifying,
        isSubscriptionStoreAvailable: _isSubscriptionStoreAvailable,
        isSubscriptionPurchasePending: _isSubscriptionPurchasePending,
        subscriptionProductDetails: _subscriptionProductDetails,
        subscriptionMessage: _subscriptionMessage,
        subscriptionError: _subscriptionError,
      ),
    );
  }

  void _updateStatus(AdFreeStatus nextStatus) {
    if (_status == nextStatus) {
      return;
    }
    _status = nextStatus;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshAdFreeStatus());
      unawaited(refreshSubscriptionEntitlement());
    }
  }

  @override
  void dispose() {
    if (_observeLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _purchaseUpdates?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }
}
