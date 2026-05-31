import '../../../core/chess/chess_board.dart';

class ChessClockTimeout {
  final PieceColor side;

  const ChessClockTimeout(this.side);
}

class ChessGameClock {
  Duration whiteRemaining;
  Duration blackRemaining;
  final Duration increment;
  PieceColor activeSide;
  bool running;
  int _turnSerial = 0;
  int? _timeoutNotifiedTurnSerial;

  ChessGameClock({
    required Duration initialWhite,
    required Duration initialBlack,
    required this.increment,
    required this.activeSide,
    this.running = false,
  })  : whiteRemaining = initialWhite,
        blackRemaining = initialBlack;

  ChessClockTimeout? tick(Duration elapsed) {
    if (!running || elapsed <= Duration.zero) return null;
    return _tickActiveSide(elapsed, stopOnTimeout: true);
  }

  ChessClockTimeout? tickPlayVsComputer({
    required Duration elapsed,
    required PieceColor userColor,
  }) {
    if (!running || elapsed <= Duration.zero) return null;
    return _tickActiveSide(
      elapsed,
      stopOnTimeout: activeSide == userColor,
    );
  }

  void applyMove({
    required PieceColor mover,
    required PieceColor nextTurn,
  }) {
    if (mover == PieceColor.white) {
      whiteRemaining += increment;
    } else {
      blackRemaining += increment;
    }
    _turnSerial += 1;
    _timeoutNotifiedTurnSerial = null;
    activeSide = nextTurn;
  }

  void start(PieceColor side) {
    _turnSerial += 1;
    _timeoutNotifiedTurnSerial = null;
    activeSide = side;
    running = true;
  }

  void stop() {
    running = false;
  }

  ChessClockTimeout? _tickActiveSide(
    Duration elapsed, {
    required bool stopOnTimeout,
  }) {
    final side = activeSide;
    final remaining = side == PieceColor.white
        ? whiteRemaining - elapsed
        : blackRemaining - elapsed;

    final clampedRemaining =
        remaining <= Duration.zero ? Duration.zero : remaining;
    if (side == PieceColor.white) {
      whiteRemaining = clampedRemaining;
    } else {
      blackRemaining = clampedRemaining;
    }

    if (remaining > Duration.zero) {
      return null;
    }

    if (stopOnTimeout) {
      running = false;
    }

    if (_timeoutNotifiedTurnSerial == _turnSerial) {
      return null;
    }
    _timeoutNotifiedTurnSerial = _turnSerial;
    return ChessClockTimeout(side);
  }
}
