import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/ads/ad_free_service.dart';
import 'package:turbo_chess/core/ads/entitlement_clock.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';
import 'package:turbo_chess/features/train/presentation/position_grid_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('all drill grids show fast navigation without range wording', (
    tester,
  ) async {
    for (final category in PositionCategory.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: PositionGridScreen(
            category: category,
            repository: _repo(category, count: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fast navigation'), findsOneWidget);
      expect(find.byKey(const ValueKey('open_jump_position_dialog')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('position_quick_jump_controls')),
          findsOneWidget);
      expect(find.textContaining('Beginner to Master'), findsNothing);
      expect(find.text('Beginner'), findsNothing);
      expect(find.text('Club'), findsNothing);
      expect(find.text('Intermediate'), findsNothing);
      expect(find.text('Advanced'), findsNothing);
      expect(find.text('Master'), findsNothing);
    }
  });

  testWidgets('jump dialog handles exact positions and invalid input', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: _repo(PositionCategory.opening, count: 10000),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('open_jump_position_dialog')),
    );

    await tester.tap(find.byKey(const ValueKey('open_jump_position_dialog')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump();
    expect(find.text('Enter a number from 1 to 10000.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      'abc',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump();
    expect(find.text('Enter a number from 1 to 10000.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      '5000',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('position_tile_5000')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open_jump_position_dialog')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      '10000',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('position_tile_10000')), findsOneWidget);
  });

  testWidgets('premium user can jump and open the correct locked position', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    final billing = _FakeBillingClient();
    final service = AdFreeService.forTesting(
      clock: _FakeEntitlementClock(DateTime.utc(2026, 1, 1, 12)),
      billingClient: billing,
    );
    await service.initialize();
    await service.grantRewardedAdFreePass();
    addTearDown(() async {
      service.dispose();
      await billing.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/train/position/drill') {
            final args = settings.arguments! as Map<String, dynamic>;
            expect(args['category'], 'opening');
            expect(args['positionIndex'], 5000);
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const Placeholder(key: ValueKey('opened_position_5000')),
            );
          }
          return null;
        },
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: _repo(PositionCategory.opening, count: 10000),
          adFreeService: service,
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('open_jump_position_dialog')),
    );

    await tester.tap(find.byKey(const ValueKey('open_jump_position_dialog')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      '5000',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('position_tile_5000')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('opened_position_5000')), findsOneWidget);
  });

  testWidgets('free locked tap shows premium dialog without rewarded ad entry',
      (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    final billing = _FakeBillingClient();
    final service = AdFreeService.forTesting(
      clock: _FakeEntitlementClock(DateTime.utc(2026, 1, 1, 12)),
      billingClient: billing,
    );
    await service.initialize();
    addTearDown(() async {
      service.dispose();
      await billing.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: _repo(PositionCategory.opening, count: 3),
          adFreeService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('position_tile_2')));
    await tester.pumpAndSettle();

    expect(find.text('Unlock all positions'), findsOneWidget);
    expect(find.text('Watch rewarded ad'), findsNothing);
    expect(find.text('Watch Ad'), findsNothing);
    expect(find.text('Subscribe'), findsWidgets);
    expect(find.text('Restore Premium'), findsOneWidget);
    expect(find.textContaining('your Google Account'), findsOneWidget);
    expect(find.textContaining('separate app account'), findsOneWidget);
    expect(
      find.textContaining('Complete earlier positions to unlock it for free'),
      findsOneWidget,
    );

    expect(service.status.isAdFree, isFalse);

    const store = PositionProgressStore();
    final progress = await store.snapshot(PositionCategory.opening);
    expect(progress.completedCount, 0);
    expect(progress.highestUnlockedIndex, 1);
  });

  testWidgets('subscribe option starts existing Google Play purchase flow', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    final billing = _FakeBillingClient()
      ..available = true
      ..response = _productResponse();
    final service = AdFreeService.forTesting(
      clock: _FakeEntitlementClock(DateTime.utc(2026, 1, 1, 12)),
      billingClient: billing,
    );
    await service.initialize();
    addTearDown(() async {
      service.dispose();
      await billing.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: _repo(PositionCategory.opening, count: 3),
          adFreeService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('position_tile_2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Subscribe'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
    await tester.pumpAndSettle();

    expect(billing.purchaseParams, hasLength(1));
    expect(
      billing.purchaseParams.single.productDetails.id,
      AdFreeProducts.subscriptionProductId,
    );
    expect(service.status.isAdFree, isFalse);
  });

  testWidgets('restore premium button restores subscription without progress', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    final billing = _FakeBillingClient()
      ..available = true
      ..response = _productResponse();
    final service = AdFreeService.forTesting(
      clock: _FakeEntitlementClock(DateTime.utc(2026, 1, 1, 12)),
      billingClient: billing,
    );
    await service.initialize();
    billing.purchasesToRestore = <PurchaseDetails>[
      _purchase(PurchaseStatus.restored),
    ];
    addTearDown(() async {
      service.dispose();
      await billing.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/train/position/drill') {
            final args = settings.arguments! as Map<String, dynamic>;
            expect(args['positionIndex'], 2);
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const Placeholder(key: ValueKey('opened_position_2')),
            );
          }
          return null;
        },
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: _repo(PositionCategory.opening, count: 3),
          adFreeService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('position_tile_2')));
    await tester.pumpAndSettle();
    final restoreButton =
        find.widgetWithText(OutlinedButton, 'Restore Premium');
    await tester.ensureVisible(restoreButton);
    await tester.pump();
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();

    expect(service.status.hasActiveSubscription, isTrue);
    expect(service.status.isAdFree, isTrue);
    expect(billing.restoreCount, greaterThanOrEqualTo(1));

    const store = PositionProgressStore();
    final progress = await store.snapshot(PositionCategory.opening);
    expect(progress.completedCount, 0);
    expect(progress.highestUnlockedIndex, 1);

    await tester.tap(find.byKey(const ValueKey('position_tile_2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('opened_position_2')), findsOneWidget);
  });
}

PositionFenRepository _repo(PositionCategory _category, {required int count}) {
  return _FakeCountPositionRepository(count);
}

Future<void> _setSurface(WidgetTester tester, Size logicalSize) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
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

PurchaseDetails _purchase(PurchaseStatus status) {
  return PurchaseDetails(
    productID: AdFreeProducts.subscriptionProductId,
    status: status,
    transactionDate: DateTime.utc(2026).millisecondsSinceEpoch.toString(),
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'google_play',
    ),
  );
}

class _FakeCountPositionRepository extends PositionFenRepository {
  final int count;

  _FakeCountPositionRepository(this.count);

  @override
  Future<int> availableCount(PositionCategory category) async => count;

  @override
  Future<String> loadFen(PositionCategory category, int positionIndex) async =>
      '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';
}

class _FakeEntitlementClock implements EntitlementClock {
  final DateTime now;

  const _FakeEntitlementClock(this.now);

  @override
  Future<EntitlementTimeSnapshot> snapshot() async {
    return EntitlementTimeSnapshot(
      deviceUtc: now,
      elapsedRealtimeMillis: 1000,
    );
  }
}

class _FakeBillingClient implements AdFreeBillingClient {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  bool available = false;
  ProductDetailsResponse response = ProductDetailsResponse(
    productDetails: const <ProductDetails>[],
    notFoundIDs: const <String>[AdFreeProducts.subscriptionProductId],
  );
  List<PurchaseDetails> purchasesToRestore = const <PurchaseDetails>[];
  final List<PurchaseParam> purchaseParams = <PurchaseParam>[];
  int restoreCount = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
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
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  Future<void> dispose() => _controller.close();
}
