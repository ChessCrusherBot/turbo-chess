import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/ads/ad_free_service.dart';
import 'package:turbo_chess/core/ads/ad_free_status_widgets.dart';
import 'package:turbo_chess/core/ads/entitlement_clock.dart';
import 'package:turbo_chess/core/ads/premium_pass_duration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeEntitlementClock clock;
  late FakeBillingClient billing;
  late AdFreeService service;
  final start = DateTime.utc(2026, 1, 1, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    clock = FakeEntitlementClock(
      EntitlementTimeSnapshot(
        deviceUtc: start,
        elapsedRealtimeMillis: 1000,
      ),
    );
    billing = FakeBillingClient();
    service = AdFreeService.forTesting(
      clock: clock,
      billingClient: billing,
    );
    await service.initialize();
  });

  tearDown(() async {
    service.dispose();
    await billing.dispose();
  });

  test('rewarded pass grants exactly 3 days', () async {
    await service.grantRewardedAdFreePass();

    expect(service.hasRewardedPass, isTrue);
    expect(service.isAdFree, isTrue);
    expect(rewardedPremiumPassDuration.inHours, 72);
    expect(
      service.rewardedPassExpiresAt,
      start.add(rewardedPremiumPassDuration),
    );
    expect(
      AdFreeStatusCopy.activeUntilLine(service.status),
      startsWith('Premium Pass active until '),
    );
  });

  test('no rewarded pass expiry stored means pass inactive', () {
    expect(service.hasRewardedPass, isFalse);
    expect(service.isAdFree, isFalse);
    expect(service.rewardedPassExpiresAt, isNull);
  });

  test('rewarded pass persists across service restart', () async {
    await service.grantRewardedAdFreePass();

    final restartBilling = FakeBillingClient();
    final restarted = AdFreeService.forTesting(
      clock: clock,
      billingClient: restartBilling,
    );
    addTearDown(() async {
      restarted.dispose();
      await restartBilling.dispose();
    });

    await restarted.initialize();

    expect(restarted.hasRewardedPass, isTrue);
    expect(restarted.isAdFree, isTrue);
    expect(
      restarted.rewardedPassExpiresAt,
      start.add(rewardedPremiumPassDuration),
    );
  });

  test('rewarded pass expires after 3 days', () async {
    await service.grantRewardedAdFreePass();

    clock.snapshotValue = EntitlementTimeSnapshot(
      deviceUtc: start.add(rewardedPremiumPassDuration).add(
            const Duration(seconds: 1),
          ),
      elapsedRealtimeMillis: rewardedPremiumPassDuration.inMilliseconds + 2000,
    );
    await service.refreshAdFreeStatus();

    expect(service.hasRewardedPass, isFalse);
    expect(service.isAdFree, isFalse);
  });

  test('corrupt rewarded pass expiry is inactive and does not crash', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ads.reward_granted_at_utc',
      start.toIso8601String(),
    );
    await prefs.setString('ads.reward_expires_at_utc', 'not-a-date');

    await service.refreshAdFreeStatus();

    expect(service.hasRewardedPass, isFalse);
    expect(service.isAdFree, isFalse);
  });

  test('second rewarded ad extends from current expiry', () async {
    await service.grantRewardedAdFreePass();

    clock.snapshotValue = EntitlementTimeSnapshot(
      deviceUtc: start.add(const Duration(hours: 1)),
      elapsedRealtimeMillis: 60 * 60 * 1000 + 1000,
    );
    await service.grantRewardedAdFreePass();

    expect(
      service.rewardedPassExpiresAt,
      start.add(rewardedPremiumPassDuration * 2),
    );
  });

  test('clock rollback does not extend rewarded entitlement', () async {
    await service.grantRewardedAdFreePass();

    clock.snapshotValue = EntitlementTimeSnapshot(
      deviceUtc: start.subtract(const Duration(hours: 2)),
      elapsedRealtimeMillis: 60 * 60 * 1000 + 1000,
    );
    await service.refreshAdFreeStatus();

    expect(service.status.hasStoredRewardedPass, isTrue);
    expect(service.status.isRewardedPassUnverifiable, isTrue);
    expect(service.hasRewardedPass, isFalse);
    expect(service.isAdFree, isFalse);
  });

  test('active subscription makes the app ad-free', () async {
    billing.addPurchase(_purchase(PurchaseStatus.purchased));
    await pumpEventQueue();

    expect(service.hasActiveSubscription, isTrue);
    expect(service.isAdFree, isTrue);
  });

  test('subscription product id is the Google Play product id', () {
    expect(AdFreeProducts.subscriptionProductId, 'turbo_chess_ad_free');
  });

  test('refresh queries product details and restores purchases', () async {
    billing.available = true;
    billing.response = _productResponse();

    await service.refreshSubscriptionEntitlement();

    expect(billing.queriedIdentifiers, hasLength(1));
    expect(
      billing.queriedIdentifiers.single,
      const <String>{AdFreeProducts.subscriptionProductId},
    );
    expect(billing.restoreCount, 1);
  });

  test('existing restored purchase on launch activates subscription', () async {
    final restoreBilling = FakeBillingClient()
      ..available = true
      ..response = _productResponse()
      ..purchasesToRestore = <PurchaseDetails>[
        _purchase(PurchaseStatus.restored),
      ];
    final restoredService = AdFreeService.forTesting(
      clock: clock,
      billingClient: restoreBilling,
    );
    addTearDown(() async {
      restoredService.dispose();
      await restoreBilling.dispose();
    });

    await restoredService.initialize();
    await pumpEventQueue();

    expect(restoredService.hasActiveSubscription, isTrue);
    expect(restoredService.isAdFree, isTrue);
    expect(restoreBilling.restoreCount, 1);
  });

  test('no restored purchase on launch keeps subscription inactive', () async {
    final restoreBilling = FakeBillingClient()
      ..available = true
      ..response = _productResponse();
    final restoredService = AdFreeService.forTesting(
      clock: clock,
      billingClient: restoreBilling,
    );
    addTearDown(() async {
      restoredService.dispose();
      await restoreBilling.dispose();
    });

    await restoredService.initialize();
    await pumpEventQueue();

    expect(restoredService.hasActiveSubscription, isFalse);
    expect(restoredService.isAdFree, isFalse);
    expect(restoreBilling.restoreCount, 1);
  });

  test('subscription has priority over suspicious rewarded pass', () async {
    await service.grantRewardedAdFreePass();
    clock.snapshotValue = EntitlementTimeSnapshot(
      deviceUtc: start.subtract(const Duration(hours: 1)),
      elapsedRealtimeMillis: 60 * 60 * 1000 + 1000,
    );
    await service.refreshAdFreeStatus();

    billing.addPurchase(_purchase(PurchaseStatus.restored));
    await pumpEventQueue();

    expect(service.status.isRewardedPassUnverifiable, isTrue);
    expect(service.hasActiveSubscription, isTrue);
    expect(service.isAdFree, isTrue);
  });

  test('subscription remains active when rewarded pass is expired', () async {
    await service.grantRewardedAdFreePass();
    clock.snapshotValue = EntitlementTimeSnapshot(
      deviceUtc: start.add(rewardedPremiumPassDuration).add(
            const Duration(seconds: 1),
          ),
      elapsedRealtimeMillis: rewardedPremiumPassDuration.inMilliseconds + 1000,
    );
    await service.refreshAdFreeStatus();

    billing.addPurchase(_purchase(PurchaseStatus.purchased));
    await pumpEventQueue();

    expect(service.hasRewardedPass, isFalse);
    expect(service.hasActiveSubscription, isTrue);
    expect(service.isAdFree, isTrue);
  });

  test('product unavailable leaves subscription inactive without crashing',
      () async {
    billing.available = true;

    await service.refreshSubscriptionEntitlement();

    expect(service.hasActiveSubscription, isFalse);
    expect(service.status.isSubscriptionStoreAvailable, isTrue);
    expect(service.status.subscriptionProductDetails, isNull);
    expect(
      service.status.subscriptionMessage,
      PremiumSubscriptionCopy.productUnavailableMessage,
    );
  });

  test('localized product price is preserved from store details', () async {
    billing.available = true;
    billing.response = _productResponse();

    await service.refreshSubscriptionEntitlement();

    expect(service.status.subscriptionProductDetails?.price, 'USD 9.99');
  });

  test('subscribe starts Google Play purchase flow for product', () async {
    billing.available = true;
    billing.response = _productResponse();
    await service.refreshSubscriptionEntitlement();

    await service.subscribeAdFree();

    expect(billing.purchaseParams, hasLength(1));
    expect(
      billing.purchaseParams.single.productDetails.id,
      AdFreeProducts.subscriptionProductId,
    );
    expect(service.status.isSubscriptionPurchasePending, isTrue);
    expect(
      service.status.subscriptionMessage,
      'Complete the purchase in Google Play.',
    );
  });

  test('manual restore active purchase activates subscription premium',
      () async {
    billing.available = true;
    billing.response = _productResponse();
    billing.purchasesToRestore = <PurchaseDetails>[
      _purchase(PurchaseStatus.restored),
    ];

    final result = await service.restorePremium();

    expect(result.status, PremiumRestoreStatus.restored);
    expect(result.message, PremiumSubscriptionCopy.restoredMessage);
    expect(service.hasActiveSubscription, isTrue);
    expect(service.isAdFree, isTrue);
    expect(billing.restoreCount, greaterThanOrEqualTo(1));
  });

  test('manual restore without purchase keeps premium false with help text',
      () async {
    billing.available = true;
    billing.response = _productResponse();

    final result = await service.restorePremium();

    expect(result.status, PremiumRestoreStatus.notFound);
    expect(service.hasActiveSubscription, isFalse);
    expect(service.isAdFree, isFalse);
    expect(result.message, contains('same Google Account'));
    expect(
      result.message,
      contains('Turbo Chess cannot restore purchases made with a different'),
    );
  });

  test('manual restore billing unavailable reports friendly retry', () async {
    billing.available = false;

    final result = await service.restorePremium();

    expect(result.status, PremiumRestoreStatus.billingUnavailable);
    expect(result.message, PremiumSubscriptionCopy.billingUnavailableMessage);
    expect(service.isAdFree, isFalse);
  });

  test('manual restore product unavailable reports friendly retry', () async {
    billing.available = true;

    final result = await service.restorePremium();

    expect(result.status, PremiumRestoreStatus.productUnavailable);
    expect(result.message, PremiumSubscriptionCopy.productUnavailableMessage);
    expect(service.isAdFree, isFalse);
  });

  test('subscribe restores existing subscription instead of launching purchase',
      () async {
    billing.available = true;
    billing.response = _productResponse();
    billing.purchasesToRestore = <PurchaseDetails>[
      _purchase(PurchaseStatus.restored),
    ];

    await service.subscribeAdFree();

    expect(service.hasActiveSubscription, isTrue);
    expect(service.isAdFree, isTrue);
    expect(billing.purchaseParams, isEmpty);
  });

  test('purchase error does not activate subscription', () async {
    billing.addPurchase(
      _purchase(
        PurchaseStatus.error,
        error: IAPError(
          source: 'google_play',
          code: 'billing_unavailable',
          message: 'Billing unavailable',
        ),
      ),
    );
    await pumpEventQueue();

    expect(service.hasActiveSubscription, isFalse);
    expect(service.status.isSubscriptionPurchasePending, isFalse);
    expect(service.status.subscriptionError, 'Billing unavailable');
  });

  test('purchase error clears an active subscription state', () async {
    billing.addPurchase(_purchase(PurchaseStatus.purchased));
    await pumpEventQueue();

    billing.addPurchase(
      _purchase(
        PurchaseStatus.error,
        error: IAPError(
          source: 'google_play',
          code: 'billing_unavailable',
          message: 'Billing unavailable',
        ),
      ),
    );
    await pumpEventQueue();

    expect(service.hasActiveSubscription, isFalse);
    expect(service.isAdFree, isFalse);
  });

  test('purchase stream error clears active subscription state', () async {
    billing.addPurchase(_purchase(PurchaseStatus.purchased));
    await pumpEventQueue();

    billing.addStreamError(Exception('stream failed'));
    await pumpEventQueue();

    expect(service.hasActiveSubscription, isFalse);
    expect(service.isAdFree, isFalse);
    expect(
      service.status.subscriptionError,
      'Subscription status could not be verified. Please try again later.',
    );
  });

  test('canceled purchase clears an active subscription state', () async {
    billing.addPurchase(_purchase(PurchaseStatus.purchased));
    await pumpEventQueue();

    billing.addPurchase(_purchase(PurchaseStatus.canceled));
    await pumpEventQueue();

    expect(service.hasActiveSubscription, isFalse);
    expect(service.isAdFree, isFalse);
    expect(service.status.subscriptionMessage, 'Purchase canceled.');
  });

  test('pending purchase remains inactive until completion', () async {
    billing.addPurchase(_purchase(PurchaseStatus.pending));
    await pumpEventQueue();

    expect(service.hasActiveSubscription, isFalse);
    expect(service.status.isSubscriptionPurchasePending, isTrue);
  });

  test('Google Play refresh can clear a stale active subscription', () async {
    billing.addPurchase(_purchase(PurchaseStatus.purchased));
    await pumpEventQueue();
    expect(service.hasActiveSubscription, isTrue);

    billing.available = true;
    billing.response = _productResponse();
    billing.purchasesToRestore = const <PurchaseDetails>[];

    await service.refreshSubscriptionEntitlement();
    await pumpEventQueue();

    expect(service.hasActiveSubscription, isFalse);
    expect(service.isAdFree, isFalse);
  });

  test('completed purchase calls completePurchase when required', () async {
    billing.addPurchase(
      _purchase(PurchaseStatus.purchased, pendingComplete: true),
    );
    await pumpEventQueue();

    expect(service.hasActiveSubscription, isTrue);
    expect(billing.completeCount, 1);
  });
}

PurchaseDetails _purchase(
  PurchaseStatus status, {
  bool pendingComplete = false,
  IAPError? error,
}) {
  final purchase = PurchaseDetails(
    productID: AdFreeProducts.subscriptionProductId,
    status: status,
    transactionDate: DateTime.utc(2026).millisecondsSinceEpoch.toString(),
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'google_play',
    ),
  );
  purchase.pendingCompletePurchase = pendingComplete;
  purchase.error = error;
  return purchase;
}

ProductDetailsResponse _productResponse() {
  return ProductDetailsResponse(
    productDetails: <ProductDetails>[
      ProductDetails(
        id: AdFreeProducts.subscriptionProductId,
        title: 'Turbo Chess Ad-free',
        description: 'Ad-free access',
        price: 'USD 9.99',
        rawPrice: 9.99,
        currencyCode: 'USD',
        currencySymbol: r'$',
      ),
    ],
    notFoundIDs: const <String>[],
  );
}

class FakeEntitlementClock implements EntitlementClock {
  EntitlementTimeSnapshot snapshotValue;

  FakeEntitlementClock(this.snapshotValue);

  @override
  Future<EntitlementTimeSnapshot> snapshot() async => snapshotValue;
}

class FakeBillingClient implements AdFreeBillingClient {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  bool available = false;
  ProductDetailsResponse response = ProductDetailsResponse(
    productDetails: const <ProductDetails>[],
    notFoundIDs: const <String>[AdFreeProducts.subscriptionProductId],
  );
  List<PurchaseDetails> purchasesToRestore = const <PurchaseDetails>[];
  final List<Set<String>> queriedIdentifiers = <Set<String>>[];
  final List<PurchaseParam> purchaseParams = <PurchaseParam>[];
  int restoreCount = 0;
  int completeCount = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queriedIdentifiers.add(Set<String>.from(identifiers));
    return response;
  }

  @override
  Future<bool> buyNonConsumable({
    required PurchaseParam purchaseParam,
  }) async {
    purchaseParams.add(purchaseParam);
    return true;
  }

  @override
  Future<List<PurchaseDetails>> restorePurchases() async {
    restoreCount += 1;
    return List<PurchaseDetails>.of(purchasesToRestore);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completeCount += 1;
  }

  void addPurchase(PurchaseDetails purchase) {
    _controller.add(<PurchaseDetails>[purchase]);
  }

  void addStreamError(Object error) {
    _controller.addError(error);
  }

  Future<void> dispose() => _controller.close();
}
