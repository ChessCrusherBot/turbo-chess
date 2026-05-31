import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/features/play_computer/domain/chess_game_clock.dart';

void main() {
  test('clock starts with initial time', () {
    final clock = ChessGameClock(
      initialWhite: const Duration(minutes: 5),
      initialBlack: const Duration(minutes: 5),
      increment: const Duration(seconds: 2),
      activeSide: PieceColor.white,
    );

    expect(clock.whiteRemaining, const Duration(minutes: 5));
    expect(clock.blackRemaining, const Duration(minutes: 5));
  });

  test('active side decrements', () {
    final clock = ChessGameClock(
      initialWhite: const Duration(seconds: 15),
      initialBlack: const Duration(seconds: 15),
      increment: Duration.zero,
      activeSide: PieceColor.white,
      running: true,
    );

    clock.tick(const Duration(seconds: 3));

    expect(clock.whiteRemaining, const Duration(seconds: 12));
    expect(clock.blackRemaining, const Duration(seconds: 15));
  });

  test('increment is added after move and turn switches', () {
    final clock = ChessGameClock(
      initialWhite: const Duration(seconds: 15),
      initialBlack: const Duration(seconds: 15),
      increment: const Duration(seconds: 2),
      activeSide: PieceColor.white,
      running: true,
    );

    clock.tick(const Duration(seconds: 4));
    clock.applyMove(mover: PieceColor.white, nextTurn: PieceColor.black);

    expect(clock.whiteRemaining, const Duration(seconds: 13));
    expect(clock.activeSide, PieceColor.black);
  });

  test('timeout stops the clock', () {
    final clock = ChessGameClock(
      initialWhite: const Duration(seconds: 2),
      initialBlack: const Duration(seconds: 15),
      increment: Duration.zero,
      activeSide: PieceColor.white,
      running: true,
    );

    final timeout = clock.tick(const Duration(seconds: 3));

    expect(timeout?.side, PieceColor.white);
    expect(clock.whiteRemaining, Duration.zero);
    expect(clock.running, isFalse);
  });

  test('Play vs Computer clock times engine side without stopping', () {
    final clock = ChessGameClock(
      initialWhite: const Duration(seconds: 15),
      initialBlack: const Duration(seconds: 15),
      increment: Duration.zero,
      activeSide: PieceColor.black,
      running: true,
    );

    final timeout = clock.tickPlayVsComputer(
      elapsed: const Duration(seconds: 3),
      userColor: PieceColor.white,
    );

    expect(timeout, isNull);
    expect(clock.blackRemaining, const Duration(seconds: 12));
    expect(clock.running, isTrue);

    final engineTimeout = clock.tickPlayVsComputer(
      elapsed: const Duration(seconds: 20),
      userColor: PieceColor.white,
    );

    expect(engineTimeout?.side, PieceColor.black);
    expect(clock.blackRemaining, Duration.zero);
    expect(clock.running, isTrue);

    clock.applyMove(mover: PieceColor.black, nextTurn: PieceColor.white);
    final userTimeout = clock.tickPlayVsComputer(
      elapsed: const Duration(seconds: 20),
      userColor: PieceColor.white,
    );

    expect(userTimeout?.side, PieceColor.white);
    expect(clock.whiteRemaining, Duration.zero);
  });

  test(
      'engine side visually reaches zero across timed presets without stopping',
      () {
    const presets = <Duration>[
      Duration(seconds: 15),
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 2),
      Duration(minutes: 3),
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
      Duration(minutes: 20),
      Duration(minutes: 30),
      Duration(minutes: 60),
    ];

    for (final base in presets) {
      final clock = ChessGameClock(
        initialWhite: base,
        initialBlack: base,
        increment: const Duration(seconds: 5),
        activeSide: PieceColor.black,
        running: true,
      );

      final timeout = clock.tickPlayVsComputer(
        elapsed: base + const Duration(seconds: 5),
        userColor: PieceColor.white,
      );

      expect(timeout?.side, PieceColor.black, reason: '$base');
      expect(clock.blackRemaining, Duration.zero, reason: '$base');
      expect(clock.running, isTrue, reason: '$base');
    }
  });

  test('engine timeout is emitted once per turn and increment can revive clock',
      () {
    final clock = ChessGameClock(
      initialWhite: const Duration(seconds: 1),
      initialBlack: const Duration(seconds: 1),
      increment: const Duration(seconds: 1),
      activeSide: PieceColor.black,
      running: true,
    );

    final firstTimeout = clock.tickPlayVsComputer(
      elapsed: const Duration(seconds: 2),
      userColor: PieceColor.white,
    );
    final repeatedTimeout = clock.tickPlayVsComputer(
      elapsed: const Duration(seconds: 1),
      userColor: PieceColor.white,
    );

    expect(firstTimeout?.side, PieceColor.black);
    expect(repeatedTimeout, isNull);
    expect(clock.running, isTrue);

    clock.applyMove(mover: PieceColor.black, nextTurn: PieceColor.white);
    expect(clock.blackRemaining, const Duration(seconds: 1));
  });

  test('user as black still sees white engine clock decrease without loss', () {
    final clock = ChessGameClock(
      initialWhite: const Duration(seconds: 15),
      initialBlack: const Duration(seconds: 15),
      increment: Duration.zero,
      activeSide: PieceColor.white,
      running: true,
    );

    final timeout = clock.tickPlayVsComputer(
      elapsed: const Duration(seconds: 16),
      userColor: PieceColor.black,
    );

    expect(timeout?.side, PieceColor.white);
    expect(clock.whiteRemaining, Duration.zero);
    expect(clock.blackRemaining, const Duration(seconds: 15));
    expect(clock.running, isTrue);
  });
}
