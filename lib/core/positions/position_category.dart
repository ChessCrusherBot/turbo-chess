enum PositionCategory {
  opening(
    id: 'opening',
    title: 'Opening Drills',
    shortTitle: 'Opening',
    assetPath: 'assets/positions/opening_positions.txt',
  ),
  middlegame(
    id: 'middlegame',
    title: 'Middlegame Drills',
    shortTitle: 'Middlegame',
    assetPath: 'assets/positions/middlegame_positions.txt',
  ),
  endgame(
    id: 'endgame',
    title: 'Endgame Drills',
    shortTitle: 'Endgame',
    assetPath: 'assets/positions/endgame_positions.txt',
  );

  final String id;
  final String title;
  final String shortTitle;
  final String assetPath;

  const PositionCategory({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.assetPath,
  });

  static PositionCategory fromId(String? id) {
    for (final category in values) {
      if (category.id == id) return category;
    }
    return PositionCategory.opening;
  }
}
