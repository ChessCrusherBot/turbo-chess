import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/audio/chess_sound_events.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/models/play_mode.dart';

void main() {
  test('normal completed move resolves to move sound', () {
    final before = ChessBoard.fromFen(ChessBoard.standardStartingFen);
    final after = ChessRules.applyUciMove(before, 'e2e4')!;

    expect(
      soundEventForCompletedMove(
        boardAfter: after,
        move: MoveRecord(
          move: 'e2e4',
          fenBefore: before.toFen(),
          fenAfter: after.toFen(),
          isUser: true,
          moveSan: 'e4',
        ),
      ),
      TurboSoundEvent.move,
    );
  });

  test('capture resolves to capture sound', () {
    const fenBefore = '8/8/8/3p4/4P3/8/8/4K2k w - - 0 1';
    final before = ChessBoard.fromFen(fenBefore);
    final after = ChessRules.applyUciMove(before, 'e4d5')!;

    expect(
      soundEventForCompletedMove(
        boardAfter: after,
        move: MoveRecord(
          move: 'e4d5',
          fenBefore: fenBefore,
          fenAfter: after.toFen(),
          isUser: true,
          moveSan: 'exd5',
        ),
      ),
      TurboSoundEvent.capture,
    );
  });

  test('check has priority over capture and normal move sounds', () {
    const fenBefore = '7k/8/8/8/8/8/4R3/4K3 w - - 0 1';
    final before = ChessBoard.fromFen(fenBefore);
    final after = ChessRules.applyUciMove(before, 'e2e8')!;

    expect(
      soundEventForCompletedMove(
        boardAfter: after,
        move: MoveRecord(
          move: 'e2e8',
          fenBefore: fenBefore,
          fenAfter: after.toFen(),
          isUser: true,
          moveSan: 'Re8+',
        ),
      ),
      TurboSoundEvent.check,
    );
  });

  test('checkmate has top sound priority', () {
    const fenBefore = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';
    const fenAfter = '7k/6Q1/5K2/8/8/8/8/8 b - - 1 1';

    expect(
      soundEventForCompletedMove(
        boardAfter: ChessBoard.fromFen(fenAfter),
        move: const MoveRecord(
          move: 'g6g7',
          fenBefore: fenBefore,
          fenAfter: fenAfter,
          isUser: true,
          moveSan: 'Qg7#',
        ),
      ),
      TurboSoundEvent.checkmate,
    );
  });
}
