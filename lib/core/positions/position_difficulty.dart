class PositionDifficulty {
  final String label;
  final int level;
  final int firstIndex;
  final int lastIndex;

  const PositionDifficulty._({
    required this.label,
    required this.level,
    required this.firstIndex,
    required this.lastIndex,
  });

  static const beginner = PositionDifficulty._(
    label: 'Beginner',
    level: 1,
    firstIndex: 1,
    lastIndex: 2000,
  );
  static const club = PositionDifficulty._(
    label: 'Club',
    level: 2,
    firstIndex: 2001,
    lastIndex: 4000,
  );
  static const intermediate = PositionDifficulty._(
    label: 'Intermediate',
    level: 3,
    firstIndex: 4001,
    lastIndex: 6000,
  );
  static const advanced = PositionDifficulty._(
    label: 'Advanced',
    level: 4,
    firstIndex: 6001,
    lastIndex: 8000,
  );
  static const master = PositionDifficulty._(
    label: 'Master',
    level: 5,
    firstIndex: 8001,
    lastIndex: 10000,
  );

  static const values = <PositionDifficulty>[
    beginner,
    club,
    intermediate,
    advanced,
    master,
  ];

  static PositionDifficulty forIndex(int positionIndex) {
    final index = positionIndex.clamp(1, 10000).toInt();
    for (final difficulty in values) {
      if (index >= difficulty.firstIndex && index <= difficulty.lastIndex) {
        return difficulty;
      }
    }
    return master;
  }
}
