/// Chess variant definitions
enum ChessVariant {
  standard('Standard', 'Classic chess rules'),
  chess960('Chess960', 'Randomized starting position'),
  kingOfTheHill('King of the Hill', 'King reaches center to win'),
  threeCheck('Three-Check', 'Check opponent 3 times to win'),
  atomic('Atomic', 'Pieces explode on capture'),
  antichess('Antichess', 'Lose all pieces to win'),
  horde('Horde', 'White has 36 pawns'),
  racingKings('Racing Kings', 'Race kings to 8th rank'),
  crazyhouse('Crazyhouse', 'Drop captured pieces');

  final String name;
  final String description;

  const ChessVariant(this.name, this.description);
}
