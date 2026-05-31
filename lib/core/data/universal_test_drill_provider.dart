import '../models/models.dart';

enum DrillPhase {
  opening,
  middlegame,
  endgame,
}

class UniversalTestDrillProvider {
  UniversalTestDrillProvider._();

  static const String universalFen =
      'rn2kb1r/pp3ppp/1q2pn2/2pp1b2/2P5/1Q1PBNP1/PP2PPBP/RN2K2R w KQkq - 0 8';

  static List<OpeningTopic> buildTopics({
    required List<OpeningTopic> sourceTopics,
    required DrillPhase phase,
  }) {
    return sourceTopics
        .map(
          (topic) => OpeningTopic(
            id: topic.id,
            label: topic.label,
            icon: topic.icon,
            color: topic.color,
            subtopics: topic.subtopics,
            drillsBySubtopic: {
              for (var index = 0; index < topic.subtopics.length; index++)
                topic.subtopics[index]: [
                  buildDrill(
                    phase: phase,
                    topicId: topic.id,
                    topicLabel: topic.label,
                    subtopic: topic.subtopics[index],
                    difficulty: _defaultDifficulty(index),
                  ),
                ],
            },
          ),
        )
        .toList(growable: false);
  }

  static ChessDrill buildDrill({
    required DrillPhase phase,
    required String topicId,
    required String topicLabel,
    required String subtopic,
    required int difficulty,
  }) {
    final phaseLabel = switch (phase) {
      DrillPhase.opening => 'opening',
      DrillPhase.middlegame => 'middlegame',
      DrillPhase.endgame => 'endgame',
    };

    return ChessDrill(
      id: '${phase.name}_${topicId}_${_slugify(subtopic)}',
      fen: universalFen,
      sideToMove: 'White',
      task: 'Play the position and convert the best plan for $topicLabel.',
      bestMove: 'Analyzing...',
      bestMoveUci: '',
      alternativeMoves: const [],
      hint: 'Start with forcing moves: checks, captures, and direct threats.',
      explanation:
          'Use this position to validate the $phaseLabel training flow for $topicLabel.',
      conceptTag: 'Live Drill',
      difficulty: difficulty.clamp(1, 5),
    );
  }

  static int _defaultDifficulty(int index) => (index % 5) + 1;

  static String _slugify(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'subtopic' : normalized;
  }
}
