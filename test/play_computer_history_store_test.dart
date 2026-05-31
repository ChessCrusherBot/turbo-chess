import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/models/play_mode.dart';
import 'package:turbo_chess/features/play_computer/data/play_computer_history_store.dart';
import 'package:turbo_chess/features/play_computer/domain/play_computer_game_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('finished game saves full user and engine move list', () async {
    const store = PlayComputerHistoryStore();
    final record = _record(
      id: 'game-one',
      moves: [
        const MoveRecord(
          move: 'e2e4',
          fenBefore: ChessBoard.standardStartingFen,
          fenAfter:
              'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
          isUser: true,
          moveNumber: 1,
          sideToMoveBefore: PieceColor.white,
          sideToMoveAfter: PieceColor.black,
          moveSan: 'e4',
        ),
        const MoveRecord(
          move: 'e7e5',
          fenBefore:
              'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
          fenAfter:
              'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
          isUser: false,
          moveNumber: 1,
          sideToMoveBefore: PieceColor.black,
          sideToMoveAfter: PieceColor.white,
          moveSan: 'e5',
        ),
      ],
    );

    await store.saveRecord(record);
    final records = await store.load();

    expect(records, hasLength(1));
    expect(records.single.moves, hasLength(2));
    expect(records.single.moves.first.isUser, isTrue);
    expect(records.single.moves.last.isUser, isFalse);
    expect(records.single.moves.first.moveSan, 'e4');
    expect(records.single.moves.last.fenAfter, contains('pppp1ppp'));
  });

  test('history is capped to latest 100 games', () async {
    const store = PlayComputerHistoryStore();

    for (var i = 0; i < 105; i++) {
      await store.saveRecord(
        _record(
          id: 'game-$i',
          endedAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        ),
      );
    }

    final records = await store.load();
    expect(records, hasLength(PlayComputerHistoryStore.maxRecords));
    expect(records.first.id, 'game-104');
    expect(records.last.id, 'game-5');
  });

  test('corrupt history JSON does not crash', () async {
    SharedPreferences.setMockInitialValues({
      PlayComputerHistoryStore.preferencesKey: [
        '{not-json',
        jsonEncode(_record(id: 'valid').toJson()),
      ],
    });

    const store = PlayComputerHistoryStore();
    final records = await store.load();

    expect(records, hasLength(1));
    expect(records.single.id, 'valid');
  });
}

PlayComputerGameRecord _record({
  required String id,
  DateTime? endedAt,
  List<MoveRecord> moves = const [],
}) {
  final safeEndedAt = endedAt ?? DateTime.utc(2026, 1, 1, 12);
  return PlayComputerGameRecord(
    id: id,
    startedAt: safeEndedAt.subtract(const Duration(minutes: 5)),
    endedAt: safeEndedAt,
    userColor: PieceColor.white,
    engineColor: PieceColor.black,
    result: 'user_checkmate_win',
    resultText: 'White wins by checkmate!',
    resultReason: 'Checkmate',
    winner: 'White',
    timeControlLabel: 'No Time Control',
    noTimeControl: true,
    engineProfileName: 'Strong',
    engineDepth: 12,
    engineSkill: 12,
    engineMoveTimeMs: 800,
    startingFen: ChessBoard.standardStartingFen,
    finalFen: ChessBoard.standardStartingFen,
    moveCount: moves.length,
    moves: moves,
  );
}
