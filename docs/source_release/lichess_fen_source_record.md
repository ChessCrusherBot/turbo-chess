# Lichess/FEN Source Record

Turbo Chess includes bundled FEN training positions derived from Lichess open database material for offline chess practice.

## Public app wording

The app Legal text states that Turbo Chess includes bundled FEN training positions derived from Lichess open database material for offline chess practice. It also states that Lichess publishes its standard open database exports under CC0 and that Turbo Chess does not use Lichess broadcast games.

## Position files

* `assets/positions/opening_positions.txt`
* `assets/positions/middlegame_positions.txt`
* `assets/positions/endgame_positions.txt`

Each bundled position file contains 10,000 FEN positions.

## Source documentation

`tools/position_factory/README.md` documents the position factory. It states that the factory uses Lichess standard game PGNs and optionally Lichess evaluated positions.

The recorded source archive for the generated launch set is:

```text
lichess_db_standard_rated_2026-04.pgn.zst
```

The source archive itself is not bundled in the app source repository because it is a large upstream data input.

## Maintainer notes

Maintainers should keep app Legal wording, root notices, source-release docs, and position-factory documentation aligned if position sources change.
