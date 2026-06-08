# Turbo Chess Position Factory

This folder is for building the launch position files:

- `assets/positions/opening_positions.txt`
- `assets/positions/middlegame_positions.txt`
- `assets/positions/endgame_positions.txt`

Each output is one valid FEN per line. The Flutter app should only bundle the
final text files; it should not bundle PGNs, eval dumps, SQLite databases, or
large drill objects.

## Why Not The Lichess Puzzle Database

Do not use `lichess_db_puzzle.csv.zst` as the main launch source. Lichess
puzzles are short tactical exercises where the solution is a narrow forced line.
Turbo Chess needs playable winning conversion positions where the user can keep
playing against the engine and only complete the drill by checkmating it.

The position factory therefore uses Lichess standard game PGNs and optionally
Lichess evaluated positions. It does not use Chess.com content.

## Sources

Use the official Lichess open database:

- Standard rated games: `https://database.lichess.org/standard/`
- Main database page: `https://database.lichess.org/`
- Evaluated positions: `https://database.lichess.org/lichess_db_eval.jsonl.zst`

The standard game files are monthly `.pgn.zst` archives named like:

```text
lichess_db_standard_rated_2026-01.pgn.zst
```

Recent monthly standard files are very large. Start with one month, run a dry
run, then expand to additional months until every phase/difficulty bucket is
full.

## Required Packages

Python packages:

```powershell
python -m pip install python-chess zstandard tqdm
```

`tqdm` is optional but useful for progress bars. `zstandard` is required for
`.zst` input. `python-chess` is required for PGN parsing, FEN validation, legal
move generation, and draw/checkmate checks.

Optional engine verification requires a Stockfish executable:

```powershell
python tools/position_factory/extract_winning_positions.py `
  --check-environment `
  --stockfish <STOCKFISH_EXECUTABLE>
```

## Preflight Before Large Processing

Before downloading or processing large files, confirm:

```powershell
python --version
python -m pip show python-chess zstandard tqdm
Get-PSDrive -PSProvider FileSystem
Get-Command stockfish -ErrorAction SilentlyContinue
```

If Stockfish is not on `PATH`, pass `--stockfish <STOCKFISH_EXECUTABLE>`.

## Extraction Commands

Dry run against one downloaded Lichess month:

```powershell
python tools/position_factory/extract_winning_positions.py `
  --pgn-zst <LICHESS_DATA>\lichess_db_standard_rated_2026-01.pgn.zst `
  --stockfish <STOCKFISH_EXECUTABLE> `
  --dry-run `
  --max-games 50000
```

Full export target:

```powershell
python tools/position_factory/extract_winning_positions.py `
  --pgn-zst <LICHESS_DATA>\lichess_db_standard_rated_2026-01.pgn.zst `
            <LICHESS_DATA>\lichess_db_standard_rated_2025-12.pgn.zst `
            <LICHESS_DATA>\lichess_db_standard_rated_2025-11.pgn.zst `
  --stockfish <STOCKFISH_EXECUTABLE> `
  --output-dir assets/positions `
  --target-per-band 2000
```

If the PGN already contains Lichess `[%eval ...]` comments, the script uses
those first. Stockfish is used only to fill missing evaluations when
`--stockfish` is provided.

Optional evaluated-position supplement:

```powershell
python tools/position_factory/extract_winning_positions.py `
  --eval-jsonl-zst <LICHESS_DATA>\lichess_db_eval.jsonl.zst `
  --output-dir assets/positions `
  --target-per-band 2000
```

Eval-only mode is less phase-accurate because the eval dump does not carry full
game context. Prefer standard game PGNs for launch.

## Phase Classification

The script classifies positions with simple, reviewable chess heuristics:

- Opening: fullmove 6-18, at least 24 pieces, at least 10 non-pawn pieces.
- Middlegame: fullmove 15-40, at least 14 pieces, at least 6 non-pawn pieces.
- Endgame: fullmove 35+, 4-14 pieces, at most 6 non-pawn pieces.

Eval-only mode cannot know the real fullmove number, so it classifies from
material only. That mode should be treated as supplemental.

## Winning Advantage Detection

PGN `[%eval ...]` comments from Lichess games are interpreted as White POV. The
script converts that to the side to move:

- White to move: user score is `eval_cp`.
- Black to move: user score is `-eval_cp`.

The candidate is accepted only when the side to move is the advantaged side.
That makes the FEN side to move the user side.

Difficulty buckets target these centipawn windows:

- Beginner: +5.00 to +9.00, with larger advantages allowed if needed.
- Club: +4.00 to +7.00.
- Intermediate: +3.00 to +6.00.
- Advanced: +2.50 to +5.00.
- Master: +2.00 to +4.00.

The final file order is always:

```text
1-2000 Beginner
2001-4000 Club
4001-6000 Intermediate
6001-8000 Advanced
8001-10000 Master
```

## Short Puzzle Avoidance

The script rejects positions that are likely to become short tactics:

- already checkmate
- stalemate
- insufficient material
- high halfmove-clock draw pressure
- side to move lacks mating material
- mate in 1
- short forced mate from engine/PV data
- too few legal moves
- too close to the end of the source game

For PGN extraction, `--min-remaining-plies 40` keeps candidates at least about
20 moves away from the source game ending. This is a heuristic, not proof that
every engine game will last 20-30 moves.

## Limitations

This factory produces strong candidates, not a final human-curated curriculum.
Before launch, sample each bucket visually and with engine self-play. In
particular:

- Some +2 positions may still be technically hard or require precise technique.
- Some +5 positions may be too easy for the intended beginner band.
- Eval-only source data has weaker phase classification.
- PGN comments and engine depth are only as good as the source analysis.
- Long conversion feel should be spot-checked by self-play, not assumed from
centipawns alone.
