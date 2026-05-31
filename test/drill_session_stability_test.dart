import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/ads/ad_free_service.dart';
import 'package:turbo_chess/core/ads/entitlement_clock.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/engine/play_vs_engine.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';
import 'package:turbo_chess/features/train/presentation/drill_detail_base.dart';
import 'package:turbo_chess/features/train/presentation/position_drill_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TurboSoundService.instance.debugResetForTesting();
  });

  testWidgets(
      'active drill does not reload after first move and premium refresh',
      (tester) async {
    final engineReply = Completer<String?>();
    final snapshots = <DrillDebugSnapshot>[];
    final repo = _repoFor(PositionCategory.endgame, [_fen1]);
    final adFreeService = _testAdFreeService();

    await _pumpPositionDrill(
      tester,
      category: PositionCategory.endgame,
      repository: repo,
      adFreeService: adFreeService,
      engineMoveProvider: (_, __, ___) => engineReply.future,
      debugOnStateChanged: snapshots.add,
    );

    final initialFen = _boardFen(tester);
    await _tapFirstLegalMove(tester);
    await tester.pump();

    expect(_boardFen(tester), isNot(initialFen));
    expect(snapshots.last.moveCount, 1);

    await adFreeService.grantRewardedAdFreePass(
      lastPassSource: 'drill_stability_test',
    );
    await tester.pump();

    expect(find.byType(ChessBoardWidget), findsOneWidget);
    expect(_boardFen(tester), isNot(initialFen));
    expect(snapshots.last.moveCount, 1);

    engineReply.complete(null);
    await tester.pump();
  });

  testWidgets('active drill does not reload after two user turns',
      (tester) async {
    final snapshots = <DrillDebugSnapshot>[];
    final repo = _repoFor(PositionCategory.endgame, [_fen1]);

    await _pumpPositionDrill(
      tester,
      category: PositionCategory.endgame,
      repository: repo,
      engineMoveProvider: _firstLegalEngineMove,
      debugOnStateChanged: snapshots.add,
    );

    final initialFen = _boardFen(tester);
    await _tapFirstLegalMove(tester);
    await tester.pumpAndSettle();
    await _tapFirstLegalMove(tester);
    await tester.pumpAndSettle();

    final activeFen = _boardFen(tester);
    expect(activeFen, isNot(initialFen));
    expect(snapshots.last.moveCount, greaterThanOrEqualTo(3));

    await _pumpPositionDrill(
      tester,
      category: PositionCategory.endgame,
      repository: repo,
      engineMoveProvider: _firstLegalEngineMove,
      debugOnStateChanged: snapshots.add,
    );
    await tester.pump();

    expect(_boardFen(tester), activeFen);
    expect(snapshots.last.moveCount, greaterThanOrEqualTo(3));
  });

  testWidgets('progress load completion does not reset active board',
      (tester) async {
    final progressRefresh = Completer<PositionProgressSnapshot>();
    final progressStore = _ProgressStoreWithPendingSecondSnapshot(
      secondSnapshot: progressRefresh,
    );
    final engineReply = Completer<String?>();
    final snapshots = <DrillDebugSnapshot>[];

    await _pumpPositionDrill(
      tester,
      category: PositionCategory.endgame,
      repository: _repoFor(PositionCategory.endgame, [_fen1]),
      progressStore: progressStore,
      engineMoveProvider: (_, __, ___) => engineReply.future,
      debugOnStateChanged: snapshots.add,
    );

    final initialFen = _boardFen(tester);
    await _tapFirstLegalMove(tester);
    await tester.pump();

    progressRefresh.complete(
      const PositionProgressSnapshot(
        highestCompletedIndex: 1,
        highestUnlockedIndex: 2,
        lastPlayedIndex: 1,
        completedIndexes: {1},
      ),
    );
    await tester.pump();

    expect(_boardFen(tester), isNot(initialFen));
    expect(snapshots.last.moveCount, 1);

    engineReply.complete(null);
    await tester.pump();
  });

  testWidgets('bookmark update does not reset active board', (tester) async {
    final engineReply = Completer<String?>();
    final snapshots = <DrillDebugSnapshot>[];

    await _pumpPositionDrill(
      tester,
      category: PositionCategory.endgame,
      repository: _repoFor(PositionCategory.endgame, [_fen1]),
      engineMoveProvider: (_, __, ___) => engineReply.future,
      debugOnStateChanged: snapshots.add,
    );

    final initialFen = _boardFen(tester);
    await _tapFirstLegalMove(tester);
    await tester.pump();

    await tester.tap(find.text('Bookmark'));
    await tester.pumpAndSettle();

    expect(_boardFen(tester), isNot(initialFen));
    expect(snapshots.last.moveCount, 1);

    engineReply.complete(null);
    await tester.pump();
  });

  testWidgets('completed-state refresh does not reset active board',
      (tester) async {
    final engineReply = Completer<String?>();
    final snapshots = <DrillDebugSnapshot>[];

    await _pumpDirectDrill(
      tester,
      fen: _fen1,
      initialPositionCompleted: false,
      engineMoveProvider: (_, __, ___) => engineReply.future,
      debugOnStateChanged: snapshots.add,
    );

    final initialFen = _boardFen(tester);
    await _tapFirstLegalMove(tester);
    await tester.pump();

    await _pumpDirectDrill(
      tester,
      fen: _fen1,
      initialPositionCompleted: true,
      engineMoveProvider: (_, __, ___) => engineReply.future,
      debugOnStateChanged: snapshots.add,
    );
    await tester.pump();

    expect(_boardFen(tester), isNot(initialFen));
    expect(snapshots.last.moveCount, 1);

    engineReply.complete(null);
    await tester.pump();
  });

  testWidgets('didUpdateWidget same position does not reload active board',
      (tester) async {
    final engineReply = Completer<String?>();
    final snapshots = <DrillDebugSnapshot>[];

    await _pumpDirectDrill(
      tester,
      fen: _fen1,
      totalPositions: 2,
      engineMoveProvider: (_, __, ___) => engineReply.future,
      debugOnStateChanged: snapshots.add,
    );

    final initialFen = _boardFen(tester);
    await _tapFirstLegalMove(tester);
    await tester.pump();

    await _pumpDirectDrill(
      tester,
      fen: _fen1,
      totalPositions: 3,
      color: Colors.deepPurple,
      engineMoveProvider: (_, __, ___) => engineReply.future,
      debugOnStateChanged: snapshots.add,
    );
    await tester.pump();

    expect(_boardFen(tester), isNot(initialFen));
    expect(snapshots.last.moveCount, 1);

    engineReply.complete(null);
    await tester.pump();
  });

  testWidgets('different position intentionally loads fresh starting FEN',
      (tester) async {
    final engineReply = Completer<String?>();

    await _pumpDirectDrill(
      tester,
      fen: _fen1,
      positionIndex: 1,
      engineMoveProvider: (_, __, ___) => engineReply.future,
    );

    await _tapFirstLegalMove(tester);
    await tester.pump();
    expect(_boardFen(tester), isNot(_fen1));

    await _pumpDirectDrill(
      tester,
      fen: _fen2,
      positionIndex: 2,
      engineMoveProvider: _firstLegalEngineMove,
    );
    await tester.pump();

    expect(_boardFen(tester), _fen2);

    engineReply.complete(null);
    await tester.pump();
  });

  testWidgets('Go to Next Position still loads next position intentionally',
      (tester) async {
    final repo = _repoFor(PositionCategory.endgame, [_fen1, _fen2]);
    const progressStore = PositionProgressStore();
    await progressStore.markCompleted(PositionCategory.endgame, 1);

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/train/position/drill') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute<void>(
              builder: (_) => PositionDrillScreen(
                category: PositionCategory.endgame,
                positionIndex: args['positionIndex'] as int,
                repository: repo,
                progressStore: progressStore,
                engineMoveProvider: _firstLegalEngineMove,
              ),
            );
          }
          return null;
        },
        home: PositionDrillScreen(
          category: PositionCategory.endgame,
          positionIndex: 1,
          repository: repo,
          progressStore: progressStore,
          engineMoveProvider: _firstLegalEngineMove,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_boardFen(tester), _fen1);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 2'), findsOneWidget);
    expect(_boardFen(tester), _fen2);
  });

  testWidgets('stale engine callback is ignored after session changes',
      (tester) async {
    final staleEngineReply = Completer<String?>();
    String? staleSearchFen;

    await _pumpDirectDrill(
      tester,
      fen: _fen1,
      positionIndex: 1,
      engineMoveProvider: (fen, _, __) {
        staleSearchFen = fen;
        return staleEngineReply.future;
      },
    );

    await _tapFirstLegalMove(tester);
    await tester.pump();
    expect(staleSearchFen, isNotNull);

    await _pumpDirectDrill(
      tester,
      fen: _fen2,
      positionIndex: 2,
      engineMoveProvider: _firstLegalEngineMove,
    );
    await tester.pump();
    expect(_boardFen(tester), _fen2);

    staleEngineReply.complete(_firstLegalMoveFromFen(staleSearchFen!));
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 2'), findsOneWidget);
    expect(_boardFen(tester), _fen2);
  });
}

const _fen1 = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';
const _fen2 = '8/8/8/3k4/8/3K4/3P4/8 w - - 0 1';

Future<String?> _firstLegalEngineMove(String fen, _, __) async {
  return _firstLegalMoveFromFen(fen);
}

String? _firstLegalMoveFromFen(String fen) {
  final legalMoves = ChessRules.getLegalMoveUcis(ChessBoard.fromFen(fen))
    ..sort();
  return legalMoves.isEmpty ? null : legalMoves.first;
}

Future<void> _pumpPositionDrill(
  WidgetTester tester, {
  required PositionCategory category,
  required PositionFenRepository repository,
  PositionProgressStore progressStore = const PositionProgressStore(),
  AdFreeService? adFreeService,
  EngineMoveProvider? engineMoveProvider,
  ValueChanged<DrillDebugSnapshot>? debugOnStateChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PositionDrillScreen(
        category: category,
        positionIndex: 1,
        repository: repository,
        progressStore: progressStore,
        adFreeService: adFreeService,
        engineMoveProvider: engineMoveProvider,
        debugOnStateChanged: debugOnStateChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDirectDrill(
  WidgetTester tester, {
  required String fen,
  int positionIndex = 1,
  int totalPositions = 2,
  Color color = Colors.teal,
  bool initialPositionCompleted = false,
  EngineMoveProvider? engineMoveProvider,
  ValueChanged<DrillDebugSnapshot>? debugOnStateChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: DrillDetailBaseScreen.position(
        category: PositionCategory.endgame,
        positionIndex: positionIndex,
        fen: fen,
        totalPositions: totalPositions,
        color: color,
        initialPositionCompleted: initialPositionCompleted,
        engineMoveProvider: engineMoveProvider,
        debugOnStateChanged: debugOnStateChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapFirstLegalMove(WidgetTester tester) async {
  final board = tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
  final legalMoves = ChessRules.getLegalMoveUcis(board.board)..sort();
  expect(legalMoves, isNotEmpty);
  final move = legalMoves.first;
  await _tapBoardSquare(tester, move.substring(0, 2));
  await _tapBoardSquare(tester, move.substring(2, 4));
}

String _boardFen(WidgetTester tester) {
  return tester
      .widget<ChessBoardWidget>(find.byType(ChessBoardWidget))
      .board
      .toFen();
}

Future<void> _tapBoardSquare(WidgetTester tester, String square) async {
  final boardFinder = find.byType(ChessBoardWidget);
  final topLeft = tester.getTopLeft(boardFinder);
  final size = tester.getSize(boardFinder);
  final squareSize = size.width / 8;
  final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(square[1]);
  final row = 8 - rank;
  await tester.tapAt(
    topLeft + Offset((file + 0.5) * squareSize, (row + 0.5) * squareSize),
  );
  await tester.pump();
}

PositionFenRepository _repoFor(
  PositionCategory category,
  List<String> fens,
) {
  return PositionFenRepository(
    bundle: _FakePositionAssetBundle({
      category.assetPath: fens.join('\n'),
    }),
  );
}

AdFreeService _testAdFreeService() {
  return AdFreeService.forTesting(
    clock: const _FakeEntitlementClock(),
    billingClient: _FakeBillingClient(),
  );
}

class _ProgressStoreWithPendingSecondSnapshot extends PositionProgressStore {
  final Completer<PositionProgressSnapshot> secondSnapshot;
  int snapshotCalls = 0;

  _ProgressStoreWithPendingSecondSnapshot({required this.secondSnapshot});

  @override
  Future<PositionProgressSnapshot> snapshot(PositionCategory category) {
    snapshotCalls += 1;
    if (snapshotCalls == 2) {
      return secondSnapshot.future;
    }
    return Future.value(
      const PositionProgressSnapshot(
        highestCompletedIndex: 0,
        highestUnlockedIndex: 1,
        lastPlayedIndex: 1,
        completedIndexes: {},
      ),
    );
  }

  @override
  Future<void> setLastPlayed(
    PositionCategory category,
    int positionIndex,
  ) async {}
}

class _FakeEntitlementClock implements EntitlementClock {
  const _FakeEntitlementClock();

  @override
  Future<EntitlementTimeSnapshot> snapshot() async {
    return EntitlementTimeSnapshot(
      deviceUtc: DateTime.utc(2026, 1, 1, 12),
      elapsedRealtimeMillis: 1000,
    );
  }
}

class _FakeBillingClient implements AdFreeBillingClient {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: const <ProductDetails>[],
      notFoundIDs: identifiers.toList(growable: false),
    );
  }

  @override
  Future<bool> buyNonConsumable({
    required PurchaseParam purchaseParam,
  }) async {
    return false;
  }

  @override
  Future<List<PurchaseDetails>> restorePurchases() async {
    return const <PurchaseDetails>[];
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

class _FakePositionAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;

  _FakePositionAssetBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    final asset = assets[key];
    if (asset == null) {
      throw StateError('Missing fake asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(asset)));
  }
}
