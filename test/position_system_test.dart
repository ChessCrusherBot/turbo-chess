import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/models/play_mode.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_completion_rules.dart';
import 'package:turbo_chess/core/positions/position_difficulty.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('position difficulty uses launch index bands', () {
    expect(PositionDifficulty.forIndex(1).label, 'Beginner');
    expect(PositionDifficulty.forIndex(2000).label, 'Beginner');
    expect(PositionDifficulty.forIndex(2001).label, 'Club');
    expect(PositionDifficulty.forIndex(4001).label, 'Intermediate');
    expect(PositionDifficulty.forIndex(6001).label, 'Advanced');
    expect(PositionDifficulty.forIndex(8001).label, 'Master');
    expect(PositionDifficulty.forIndex(10000).label, 'Master');
  });

  test('launch position assets contain 10000 valid FENs per module', () {
    final allSeen = <String>{};
    for (final category in PositionCategory.values) {
      final path = File(category.assetPath);
      expect(path.existsSync(), isTrue, reason: category.assetPath);
      final fens = path
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);

      expect(fens, hasLength(10000), reason: category.id);
      expect(fens.toSet(), hasLength(10000), reason: category.id);

      for (final fen in fens) {
        _expectValidLaunchFen(fen);
        expect(allSeen.add(fen), isTrue, reason: 'cross-file duplicate $fen');
      }
    }
  });

  test('FEN repository lazily counts and loads by 1-based index', () async {
    final repo = PositionFenRepository(
      bundle: _FakePositionAssetBundle({
        PositionCategory.opening.assetPath: [
          '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
          '',
          '8/8/4k3/8/3K4/4P3/8/8 w - - 0 1',
        ].join('\n'),
      }),
    );

    expect(repo.getPositionCount(PositionCategory.opening), 0);
    expect(await repo.availableCount(PositionCategory.opening), 2);
    expect(repo.getPositionCount(PositionCategory.opening), 2);
    expect(
      await repo.getFen(PositionCategory.opening, 2),
      '8/8/4k3/8/3K4/4P3/8/8 w - - 0 1',
    );
    expect(repo.isValidPositionIndex(0), isFalse);
    expect(repo.isValidPositionIndex(10000), isTrue);
    expect(repo.difficultyForIndex(8001), 'Master');
    expect(
      repo.loadFen(PositionCategory.opening, 3),
      throwsA(isA<RangeError>()),
    );
  });

  test('real repository loads opening position 1 and 10000', () async {
    final repo = PositionFenRepository();
    await repo.loadModule(PositionCategory.opening);

    expect(repo.getPositionCount(PositionCategory.opening), 10000);
    _expectValidLaunchFen(await repo.getFen(PositionCategory.opening, 1));
    _expectValidLaunchFen(await repo.getFen(PositionCategory.opening, 10000));
    expect(repo.getFen(PositionCategory.opening, 10001),
        throwsA(isA<RangeError>()));
  });

  test('progress defaults keep legacy unlock value but all indexes are open',
      () async {
    SharedPreferences.setMockInitialValues({});
    const store = PositionProgressStore();
    final progress = await store.snapshot(PositionCategory.opening);

    expect(progress.highestCompletedIndex, 0);
    expect(progress.highestUnlockedIndex, 1);
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 1,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 2,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 10000,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 0,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isFalse,
    );
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 10001,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isFalse,
    );
  });

  test('user checkmate completion records completion progress', () async {
    SharedPreferences.setMockInitialValues({});
    const store = PositionProgressStore();

    expect(
      PositionCompletionRules.isUserCheckmateWin(
        result: const GameEndResult(
          reason: 'Checkmate',
          winner: 'White',
          message: 'White wins by checkmate!',
        ),
        userColor: PieceColor.white,
      ),
      isTrue,
    );

    await store.markCompleted(PositionCategory.opening, 1);
    final progress = await store.snapshot(PositionCategory.opening);
    expect(progress.isCompleted(1), isTrue);
    expect(progress.highestUnlockedIndex, 2);
  });

  test('engine checkmate and draws do not satisfy completion rule', () {
    expect(
      PositionCompletionRules.isUserCheckmateWin(
        result: const GameEndResult(
          reason: 'Checkmate',
          winner: 'Black',
          message: 'Black wins by checkmate!',
        ),
        userColor: PieceColor.white,
      ),
      isFalse,
    );
    expect(
      PositionCompletionRules.isUserCheckmateWin(
        result: const GameEndResult(
          reason: 'Stalemate',
          winner: null,
          message: 'Draw by stalemate.',
        ),
        userColor: PieceColor.white,
      ),
      isFalse,
    );
    expect(
      PositionCompletionRules.isUserCheckmateWin(
        result: const GameEndResult(
          reason: 'Threefold Repetition',
          winner: null,
          message: 'Draw by repetition.',
        ),
        userColor: PieceColor.white,
      ),
      isFalse,
    );
  });

  test('all positions are accessible without changing progress path', () async {
    SharedPreferences.setMockInitialValues({});
    const store = PositionProgressStore();
    await store.markCompleted(PositionCategory.endgame, 1);
    final progress = await store.snapshot(PositionCategory.endgame);

    expect(progress.completedCount, 1);
    expect(progress.highestUnlockedIndex, 2);
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 10000,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: true,
      ),
      isTrue,
    );
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 2,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 10000,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );

    final afterAccessCheck = await store.snapshot(PositionCategory.endgame);
    expect(afterAccessCheck.completedCount, 1);
    expect(afterAccessCheck.highestUnlockedIndex, 2);
    expect(afterAccessCheck.highestCompletedIndex, 1);
  });
}

void _expectValidLaunchFen(String fen) {
  const startingFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  expect(fen, isNot(startingFen));
  expect(fen.trim(), fen);

  final tokens = fen.split(RegExp(r'\s+'));
  expect(tokens, hasLength(6), reason: fen);
  expect(tokens[1] == 'w' || tokens[1] == 'b', isTrue, reason: fen);
  expect(int.tryParse(tokens[4]), isNotNull, reason: fen);
  expect(int.tryParse(tokens[5]), isNotNull, reason: fen);

  final rows = tokens.first.split('/');
  expect(rows, hasLength(8), reason: fen);
  var whiteKings = 0;
  var blackKings = 0;
  for (final row in rows) {
    var files = 0;
    for (final char in row.split('')) {
      final digit = int.tryParse(char);
      if (digit != null) {
        files += digit;
      } else {
        expect('pnbrqkPNBRQK'.contains(char), isTrue, reason: fen);
        files += 1;
        if (char == 'K') whiteKings += 1;
        if (char == 'k') blackKings += 1;
      }
    }
    expect(files, 8, reason: fen);
  }
  expect(whiteKings, 1, reason: fen);
  expect(blackKings, 1, reason: fen);

  final board = ChessBoard.fromFen(fen);
  expect(board.toFen(), fen, reason: fen);
  expect(ChessRules.isCheckmate(board, board.turn), isFalse, reason: fen);
  expect(ChessRules.isStalemate(board, board.turn), isFalse, reason: fen);
  expect(ChessRules.isInsufficientMaterial(board), isFalse, reason: fen);
  expect(ChessRules.getLegalMoveUcis(board), isNotEmpty, reason: fen);
  expect(_sideToMoveHasMatingMaterial(board), isTrue, reason: fen);
}

bool _sideToMoveHasMatingMaterial(ChessBoard board) {
  final ownTypes = board.pieces.values
      .where((piece) => piece.color == board.turn)
      .map((piece) => piece.type)
      .toList(growable: false);
  if (ownTypes.contains(PieceType.queen) ||
      ownTypes.contains(PieceType.rook) ||
      ownTypes.contains(PieceType.pawn)) {
    return true;
  }
  final bishops = ownTypes.where((type) => type == PieceType.bishop).length;
  final knights = ownTypes.where((type) => type == PieceType.knight).length;
  return bishops >= 2 ||
      (bishops >= 1 && knights >= 1) ||
      bishops + knights >= 3;
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
