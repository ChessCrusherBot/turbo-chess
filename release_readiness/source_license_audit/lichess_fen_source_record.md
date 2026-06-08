# Turbo Chess Lichess/FEN Source Record

This is internal source documentation. Do not copy unfinished source-record placeholders into public app UI.

## Public App Wording

The public app Legal wording currently says Turbo Chess includes bundled FEN training positions derived from Lichess open database material for offline chess practice. It says Lichess publishes its standard open database exports under CC0, and Turbo Chess does not use Lichess broadcast games.

## Local Evidence Found

* Position files:
  * `assets/positions/opening_positions.txt`
  * `assets/positions/middlegame_positions.txt`
  * `assets/positions/endgame_positions.txt`
* Each position file has 10,000 lines according to `tools/position_factory/reports/position_asset_validation_report.txt`.
* `tools/position_factory/README.md` says the factory uses Lichess standard game PGNs and optionally Lichess evaluated positions. It explicitly says the project does not use Chess.com content and does not use the Lichess puzzle database as the main launch source.
* `tools/position_factory/reports/extraction_log.txt` records the Lichess standard database index and the latest available standard month used during generation.
* `tools/position_factory/reports/full_extraction_report.txt` records accepted positions, source evaluation types, and final export counts.
* `tools/position_factory/reports/position_quality_summary.json` records that all three exported assets have 10,000 metadata matches.

## Exact Source Archive/Month/Export

Exact source archive/month/export: `lichess_db_standard_rated_2026-04.pgn.zst`

Local reports show this was the Lichess standard rated PGN archive used by the position factory. Reports contain local machine paths to the archive; keep those reports internal unless deliberately cleaned for public source release.

## Notes For Human Review

* Confirm whether `lichess_db_standard_rated_2026-04.pgn.zst` should be named in public source docs.
* Do not put unfinished source/archive reminders in app UI.
* Do not change FEN files as part of source documentation.
