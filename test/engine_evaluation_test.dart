import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/engine_evaluation.dart';
import 'package:turbo_chess/core/engine/uci_parser.dart';
import 'package:turbo_chess/features/play_computer/presentation/play_vs_computer_screen.dart';

void main() {
  test('formats centipawn values for display', () {
    expect(debugFormatPlayEvaluation(20), '+0.2');
    expect(debugFormatPlayEvaluation(-50), '-0.5');
    expect(debugFormatPlayEvaluation(0), '0.0');
  });

  test('formats mate values for display', () {
    expect(debugFormatPlayEvaluation(EngineEvaluation.encodeMate(3)), '+M3');
    expect(debugFormatPlayEvaluation(EngineEvaluation.encodeMate(-2)), '-M2');
  });

  test('maps evaluation bar from white-positive perspective', () {
    expect(debugWhiteEvaluationShare(120), greaterThan(0.5));
    expect(debugWhiteEvaluationShare(-120), lessThan(0.5));
    expect(debugWhiteEvaluationShare(0), closeTo(0.5, 0.001));
    expect(
      debugWhiteEvaluationShare(EngineEvaluation.encodeMate(4)),
      greaterThan(0.9),
    );
  });

  test('converts side-to-move scores to white-positive scores', () {
    expect(
      EngineEvaluation.toWhitePerspective(75, PieceColor.white),
      75,
    );
    expect(
      EngineEvaluation.toWhitePerspective(75, PieceColor.black),
      -75,
    );
  });

  test('parses UCI centipawn and mate scores', () {
    final cp = UCIParser.parseInfoLine('info depth 12 score cp 20 nodes 10');
    final mate =
        UCIParser.parseInfoLine('info depth 12 score mate -2 nodes 10');

    expect(cp?.score, 20);
    expect(cp?.scoreString, '+0.2');
    expect(mate?.score, EngineEvaluation.encodeMate(-2));
    expect(mate?.scoreString, '-M2');
  });
}
