#!/usr/bin/env python3
"""Validate Turbo Chess launch FEN text assets."""

from __future__ import annotations

import argparse
import collections
import dataclasses
import datetime as dt
from pathlib import Path

try:
    import chess
except ImportError as exc:  # pragma: no cover - startup guard
    raise SystemExit(
        "Missing required package 'python-chess'. Install with:\n"
        "  python -m pip install python-chess"
    ) from exc


ASSETS = {
    "opening": Path("assets/positions/opening_positions.txt"),
    "middlegame": Path("assets/positions/middlegame_positions.txt"),
    "endgame": Path("assets/positions/endgame_positions.txt"),
}
EXPECTED_LINES = 10_000
STARTING_EPD = chess.Board().epd(en_passant="legal")


@dataclasses.dataclass
class FileValidation:
    name: str
    path: Path
    line_count: int = 0
    duplicate_count: int = 0
    errors: collections.Counter[str] = dataclasses.field(
        default_factory=collections.Counter
    )

    @property
    def passed(self) -> bool:
        return self.line_count == EXPECTED_LINES and not self.errors


def main() -> int:
    args = parse_args()
    args.report.parent.mkdir(parents=True, exist_ok=True)

    results: list[FileValidation] = []
    all_seen: set[str] = set()
    cross_duplicates = 0

    for name, path in ASSETS.items():
        result, epds = validate_file(name, path, args.expected_lines)
        results.append(result)
        for epd in epds:
            if epd in all_seen:
                cross_duplicates += 1
            all_seen.add(epd)

    passed = all(result.passed for result in results) and cross_duplicates == 0
    write_report(args.report, results, cross_duplicates, passed)
    print(f"validation_report={args.report}")
    print(f"validation_passed={passed}")
    return 0 if passed else 1


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--report",
        type=Path,
        default=Path("tools/position_factory/reports/position_asset_validation_report.txt"),
    )
    parser.add_argument("--expected-lines", type=int, default=EXPECTED_LINES)
    return parser.parse_args()


def validate_file(
    name: str,
    path: Path,
    expected_lines: int,
) -> tuple[FileValidation, list[str]]:
    result = FileValidation(name=name, path=path)
    epds: list[str] = []
    seen: set[str] = set()

    if not path.exists():
        result.errors["missing_file"] += 1
        return result, epds

    raw_lines = path.read_text(encoding="utf-8").splitlines()
    for line_number, raw in enumerate(raw_lines, start=1):
        fen = raw.strip()
        if not fen:
            result.errors["blank_line"] += 1
            continue

        result.line_count += 1
        board = parse_board(fen, result)
        if board is None:
            continue

        epd = board.epd(en_passant="legal")
        if epd in seen:
            result.duplicate_count += 1
            result.errors["duplicate_in_file"] += 1
        seen.add(epd)
        epds.append(epd)

        validate_board(board, result)
        validate_band(line_number, result)

    if result.line_count != expected_lines:
        result.errors["wrong_line_count"] += 1
    return result, epds


def parse_board(fen: str, result: FileValidation) -> chess.Board | None:
    try:
        board = chess.Board(fen)
    except ValueError:
        result.errors["illegal_fen"] += 1
        return None
    if not board.is_valid():
        result.errors["invalid_board"] += 1
        return None
    return board


def validate_board(board: chess.Board, result: FileValidation) -> None:
    if board.epd(en_passant="legal") == STARTING_EPD:
        result.errors["starting_position"] += 1
    if board.is_checkmate():
        result.errors["already_checkmate"] += 1
    if board.is_stalemate():
        result.errors["stalemate"] += 1
    if board.is_insufficient_material():
        result.errors["insufficient_material"] += 1
    if board.legal_moves.count() <= 0:
        result.errors["no_legal_moves"] += 1
    if not side_has_mating_material(board, board.turn):
        result.errors["side_to_move_no_mating_material"] += 1


def validate_band(line_number: int, result: FileValidation) -> None:
    if 1 <= line_number <= 2000:
        return
    if 2001 <= line_number <= 4000:
        return
    if 4001 <= line_number <= 6000:
        return
    if 6001 <= line_number <= 8000:
        return
    if 8001 <= line_number <= 10000:
        return
    result.errors["line_outside_launch_bands"] += 1


def side_has_mating_material(board: chess.Board, color: chess.Color) -> bool:
    pieces = board.piece_map().values()
    own_types = [piece.piece_type for piece in pieces if piece.color == color]
    if chess.QUEEN in own_types or chess.ROOK in own_types or chess.PAWN in own_types:
        return True
    bishops = own_types.count(chess.BISHOP)
    knights = own_types.count(chess.KNIGHT)
    return bishops >= 2 or (bishops >= 1 and knights >= 1) or bishops + knights >= 3


def write_report(
    path: Path,
    results: list[FileValidation],
    cross_duplicates: int,
    passed: bool,
) -> None:
    lines = [
        "Turbo Chess Position Asset Validation Report",
        f"created_utc: {dt.datetime.now(dt.UTC).isoformat(timespec='seconds')}",
        f"passed: {passed}",
        f"expected_lines_per_file: {EXPECTED_LINES}",
        f"cross_file_duplicate_count: {cross_duplicates}",
        "",
    ]

    for result in results:
        lines.extend(
            [
                f"{result.name}:",
                f"- path: {result.path}",
                f"- line_count: {result.line_count}",
                f"- duplicate_count: {result.duplicate_count}",
                f"- passed: {result.passed}",
                "- errors:",
            ]
        )
        if result.errors:
            for key, value in sorted(result.errors.items()):
                lines.append(f"  - {key}: {value}")
        else:
            lines.append("  - none: 0")
        lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
