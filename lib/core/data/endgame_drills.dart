import '../models/models.dart';
import 'universal_test_drill_provider.dart';

/// Complete Endgame Drills curriculum from chess-endgame-drills.jsx.
class EndgameDrillsData {
  EndgameDrillsData._();

  static List<OpeningTopic> get allTopics =>
      UniversalTestDrillProvider.buildTopics(
        sourceTopics: _baseTopics,
        phase: DrillPhase.endgame,
      );

  static List<OpeningTopic> get _baseTopics => _topicSpecs
      .map(
        (spec) => OpeningTopic(
          id: spec.id,
          label: spec.label,
          icon: spec.icon,
          color: spec.color,
          subtopics: spec.subtopics,
        ),
      )
      .toList(growable: false);

  static ChessDrill getDrillForSubtopic(String topicId, String subtopic) {
    final topics = allTopics;
    final topic = topics.firstWhere(
      (item) => item.id == topicId,
      orElse: () => topics.first,
    );
    final drills = topic.getDrillsForSubtopic(subtopic);
    if (drills.isNotEmpty) return drills.first;

    final subtopicIndex = topic.subtopics.indexOf(subtopic);
    final safeIndex = subtopicIndex < 0 ? 0 : subtopicIndex;
    final safeSubtopic = subtopicIndex < 0 ? topic.subtopics.first : subtopic;
    return UniversalTestDrillProvider.buildDrill(
      phase: DrillPhase.endgame,
      topicId: topic.id,
      topicLabel: topic.label,
      subtopic: safeSubtopic,
      difficulty: safeIndex + 1,
    );
  }
}

class _TopicSpec {
  final String id;
  final String label;
  final String icon;
  final String color;
  final List<String> subtopics;

  const _TopicSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.subtopics,
  });
}

const List<_TopicSpec> _topicSpecs = [
  _TopicSpec(
    id: 'ke',
    label: 'King & Pawn',
    icon: '♙',
    color: '#c8a96e',
    subtopics: [
      'K+P vs K: Opposition & Key Squares',
      'K+P vs K: Distant Opposition',
      'K+P vs K: Rook Pawn (a/h) Draw',
      'K+P vs K: Shouldering & Outflanking',
      'K+P vs K: Triangulation',
      'K+2P vs K: Connected Pawns',
      'K+2P vs K: Doubled Pawns',
      'K+2P vs K: Isolated Pawns',
      'K+P vs K+P: Passed Pawn Race',
      'K+P vs K+P: Breakthrough',
      'K+P vs K+P: Blocked Pawns',
      'K+2P vs K+P: Minority Attack',
      'K+2P vs K+2P: Zugzwang',
      'K+2P vs K+2P: Outside Passed Pawn',
      'Pawn Promotion Races',
      'Underpromotion Tactics',
      'Backward Pawn Endgames',
      'Isolated Pawn Endgames',
      'Stalemate Traps in Pawn Endings',
      'Pawn Structures: Chain vs Chain',
    ],
  ),
  _TopicSpec(
    id: 're',
    label: 'Rook Endings',
    icon: '♖',
    color: '#7eb8d4',
    subtopics: [
      'R vs K: Basic Checkmate',
      'R+P vs K: Winning Technique',
      'R+P vs R: Philidor Position (Draw)',
      'R+P vs R: Lucena Position (Win)',
      'R+P vs R: Rook Behind Passed Pawn',
      'R+P vs R: Cutting Off the King',
      'R+2P vs R: 7th Rank Rook',
      'R+2P vs R: Passed Pawn + Rook',
      'R+2P vs R+P: Pawn Up Technique',
      'R+3P vs R+2P: Endgame Conversion',
      'Rook Activity Principles',
      'Tarrasch Rule (Rook Behind Pawn)',
      'Rook vs 2 Connected Pawns',
      'Skewer & Pin Tactics in Rook Endings',
      'Stalemate Resources in Rook Endings',
      'Rook Ending: Bridging (Lucena Bridge)',
      'Rook vs R+Rook Pawn',
      'Rook Endings: King Activity',
      'Rook Endings: 4th Rank Defense',
      'Rook Endings: Checking Distance',
    ],
  ),
  _TopicSpec(
    id: 'qe',
    label: 'Queen Endings',
    icon: '♕',
    color: '#e8c56e',
    subtopics: [
      'Q vs K: Basic Checkmate',
      'Q vs K: Staircase Mate',
      'Q+P vs Q: Drawing Tricks',
      'Q+P vs Q: Winning Technique',
      'Q vs R: Winning Technique',
      'Q vs R+P: Complex Defense',
      'Q vs 2R: Positional Ideas',
      'Q vs B+N: Checkmate or Draw?',
      'Q+P vs Q+P: King Activity',
      'Q Endgame: Perpetual Check Defense',
      'Q Endgame: Stalemate Traps',
      'Q Endgame: Queen Centralization',
    ],
  ),
  _TopicSpec(
    id: 'be',
    label: 'Bishop Endings',
    icon: '♗',
    color: '#a8d8a8',
    subtopics: [
      'B+B vs K: Checkmate Technique',
      'B vs K: Why It\'s a Draw',
      'B+P vs K: Key Squares',
      'B+P vs B (Same Color): Winning/Drawing',
      'B+P vs B (Opposite Color): Fortress',
      'Good Bishop vs Bad Bishop',
      'Bishop vs Pawn (Winning/Drawing)',
      'B+2P vs B: Passed Pawn',
      'B Ending: Wrong Color Bishop Draw',
      'B Ending: Pawn Breakthrough',
      'Opposite Color Bishops: Drawing Technique',
      'Opposite Color Bishops: Winning Technique',
    ],
  ),
  _TopicSpec(
    id: 'ne',
    label: 'Knight Endings',
    icon: '♘',
    color: '#d4a8d4',
    subtopics: [
      'N+B vs K: Checkmate (Full Method)',
      'N vs K: Why It\'s a Draw',
      'N+P vs K: Winning Technique',
      'N+P vs N: Activity Principle',
      'N vs P (Blockade)',
      'N+2P vs N: Passed Pawn',
      'Knight Endings: Outpost',
      'Knight Endings: King Activity',
      'Knight Endings: Zugzwang',
      'Knight vs Knight Maneuvering',
    ],
  ),
  _TopicSpec(
    id: 'bvn',
    label: 'Bishop vs Knight',
    icon: '⚔',
    color: '#e8a898',
    subtopics: [
      'B vs N: Open Position Advantage',
      'B vs N: Closed Position Disadvantage',
      'B vs N: Outpost Knight',
      'B vs N: Two Results Positions',
      'B vs N+P: Drawing Technique',
      'B+P vs N: Winning Technique',
      'B vs N: Knight on the Rim',
      'B vs N: Fortress Ideas',
    ],
  ),
  _TopicSpec(
    id: 're_minor',
    label: 'Rook vs Minor',
    icon: '♜',
    color: '#98c8e8',
    subtopics: [
      'R vs B: Winning Technique',
      'R vs N: Winning Technique',
      'R vs B+P: Defensive Technique',
      'R vs N+P: Defensive Technique',
      'R vs 2B: Positional Balance',
      'R vs 2N: Positional Balance',
      'R+P vs B: Edge Cases',
      'R+P vs N: Skewer Tactics',
    ],
  ),
  _TopicSpec(
    id: 're_two',
    label: 'Rook vs Two Pieces',
    icon: '♜♟',
    color: '#b8d4c8',
    subtopics: [
      'R+P vs B+N: Practical Defense',
      '2R vs Q: Piece Activity',
      'R+B vs R: Extra Exchange',
      'R+N vs R: Extra Exchange',
    ],
  ),
  _TopicSpec(
    id: 'pawn_struct',
    label: 'Pawn Structure Mastery',
    icon: '♟♟',
    color: '#d4c8a8',
    subtopics: [
      'Passed Pawn: Creation & Promotion',
      'Passed Pawn: Outside Passed Pawn',
      'Candidate Pawn: Breakthrough',
      'Isolated Pawn: Attack & Defense',
      'Backward Pawn: Weakness Exploitation',
      'Doubled Pawns: Structural Weakness',
      'Hanging Pawns: Dynamic vs Static',
      'Pawn Majority: Queenside vs Kingside',
      'Pawn Minority Attack',
      'Pawn Chain: Attacking the Base',
      'Pawn Chain: En Passant Tricks',
      'Fortress Construction',
      'Zugzwang: Pawn Endings',
      'Triangulation: King Maneuver',
      'Corresponding Squares',
      'Square of the Pawn Rule',
    ],
  ),
  _TopicSpec(
    id: 'zugzwang',
    label: 'Zugzwang & Geometry',
    icon: '∞',
    color: '#c8b4d4',
    subtopics: [
      'Zugzwang: King & Pawn',
      'Zugzwang: Rook Endgame',
      'Zugzwang: Minor Piece',
      'Triangulation: Basic',
      'Triangulation: Advanced',
      'Corresponding Squares: Theory',
      'Mined Squares',
      'King Geometry: Shortest Path',
      'Opposition: Direct',
      'Opposition: Distant',
      'Opposition: Diagonal',
    ],
  ),
  _TopicSpec(
    id: 'tactical',
    label: 'Endgame Tactics',
    icon: '⚡',
    color: '#e8d468',
    subtopics: [
      'Skewer in Endgame',
      'Fork in Endgame',
      'Pin in Endgame',
      'Discovered Attack in Endgame',
      'Double Check in Endgame',
      'Deflection in Endgame',
      'Decoy in Endgame',
      'Overloading in Endgame',
      'Interference in Endgame',
      'Zwischenzug in Endgame',
      'Stalemate Trick',
      'Perpetual Check',
      'Underpromotion Tactic',
      'Pawn Promotion Fork',
      'Back Rank Weakness',
    ],
  ),
  _TopicSpec(
    id: 'technique',
    label: 'Converting Advantage',
    icon: '🏆',
    color: '#e8c890',
    subtopics: [
      'Converting Extra Pawn: K+P Endings',
      'Converting Extra Pawn: Rook Endings',
      'Converting Exchange Advantage',
      'Simplification to Winning Endgame',
      'Avoiding Stalemate While Winning',
      'Avoiding Fortress While Winning',
      'Breaking a Fortress',
      'King Activation in Endgame',
      'Principle of Two Weaknesses',
      'Creating a Passed Pawn',
    ],
  ),
  _TopicSpec(
    id: 'defense',
    label: 'Defensive Technique',
    icon: '🛡',
    color: '#98d4a8',
    subtopics: [
      'Building a Fortress: Rook Ending',
      'Building a Fortress: Minor Piece',
      'Perpetual Check Defense',
      'Stalemate Salvation',
      'Drawing vs Q with Rook Pawn',
      'Defending vs Outside Passed Pawn',
      'Active King in Defense',
      'Counterplay Creation',
      'Sacrificing for a Draw',
      'Blockade Technique',
    ],
  ),
  _TopicSpec(
    id: 'queen_vs',
    label: 'Queen vs Pieces',
    icon: '♛',
    color: '#f0c060',
    subtopics: [
      'Q vs R: Step-by-Step Win',
      'Q vs 2B: Winning Method',
      'Q vs B+N: Winning Method',
      'Q vs 3 Pawns: Dynamic Balance',
      'Q vs R+B: Positional Ideas',
    ],
  ),
  _TopicSpec(
    id: 'master',
    label: 'Master-Level Complex',
    icon: '👑',
    color: '#e87860',
    subtopics: [
      'Q+R vs Q+R: Technique',
      'R+B vs R+N: Subtle Differences',
      'Multi-Pawn Endgames: 3 vs 2',
      'Multi-Pawn Endgames: 4 vs 3',
      'Rook + 2P vs Rook + 2P: Same Side',
      'Rook + 2P vs Rook + 2P: Opposite Side',
      'Endgame Planning: Long-Range',
      'Practical Decision Making',
      'Clock & Endgame Psychology',
    ],
  ),
  _TopicSpec(
    id: 'famous',
    label: 'Famous Endgames',
    icon: '📜',
    color: '#b8a8d4',
    subtopics: [
      'Lucena Position (Historical)',
      'Philidor Position (Historical)',
      'Réti\'s Famous Study',
      'Saavedra Study',
      'Troitsky Theme',
      'Rinck Studies',
      'Classic Endgame: Fischer\'s Technique',
      'Classic Endgame: Capablanca Precision',
      'Classic Endgame: Karpov Technique',
      'Classic Endgame: Carlsen Technique',
    ],
  ),
  _TopicSpec(
    id: 'speed',
    label: 'Speed Drills',
    icon: '⏱',
    color: '#e89870',
    subtopics: [
      '30-Second: Find the Key Square',
      '30-Second: Is it Win/Draw/Loss?',
      '30-Second: Best First Move',
      'Blitz: Rook Endgame Decisions',
      'Blitz: Pawn Race Calculation',
      'Rapid: Full Endgame Conversion',
    ],
  ),
  _TopicSpec(
    id: 'study',
    label: 'Endgame Studies',
    icon: '🔬',
    color: '#a8c8d8',
    subtopics: [
      'Composed Studies: Win',
      'Composed Studies: Draw',
      'Retrograde Analysis',
      'Study: Knight Domination',
      'Study: Pawn Geometry',
      'Study: Rook Magic',
      'Study: Queen Geometry',
      'Study: Mutual Zugzwang',
    ],
  ),
];
