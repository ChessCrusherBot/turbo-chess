import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/engine/play_vs_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('play engine accepts the first king move', () async {
    SharedPreferences.setMockInitialValues({});

    final game = PlayVsEngine(
      startingFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
    );

    game.start();

    expect(game.state, PlayState.userTurn);
    expect(game.getLegalMovesFrom('e3'), contains('d3'));
    expect(await game.userMove('e3', 'd3'), isTrue);
    expect(game.moves.first.move, 'e3d3');
  });
}
