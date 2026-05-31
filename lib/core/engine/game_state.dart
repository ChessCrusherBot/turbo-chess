import '../chess/chess_board.dart';

/// Tracks the complete state of a playable chess game.
class GameState {
  final List<String> fenHistory;
  final String initialFen;
  int _currentIndex;

  GameState({required this.initialFen})
      : fenHistory = [],
        _currentIndex = -1;

  int get currentIndex => _currentIndex;
  bool get canGoBack => _currentIndex > -1;
  bool get canGoForward => _currentIndex < fenHistory.length - 1;

  ChessBoard get currentBoard {
    if (_currentIndex < 0) return ChessBoard.fromFen(initialFen);
    return ChessBoard.fromFen(fenHistory[_currentIndex]);
  }

  String get currentFen {
    if (_currentIndex < 0) return initialFen;
    return fenHistory[_currentIndex];
  }

  void addMove(String newFen) {
    if (_currentIndex < fenHistory.length - 1) {
      fenHistory.removeRange(_currentIndex + 1, fenHistory.length);
    }
    fenHistory.add(newFen);
    _currentIndex = fenHistory.length - 1;
  }

  void goBack() {
    if (canGoBack) _currentIndex--;
  }

  void goForward() {
    if (canGoForward) _currentIndex++;
  }

  void goToIndex(int index) {
    if (index >= -1 && index < fenHistory.length) {
      _currentIndex = index;
    }
  }

  void goToStart() => _currentIndex = -1;
  void goToEnd() => _currentIndex = fenHistory.length - 1;
}
