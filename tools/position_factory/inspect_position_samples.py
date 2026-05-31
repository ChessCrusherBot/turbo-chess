#!/usr/bin/env python3
"""Summarize Turbo Chess position candidate metadata and final FEN assets."""

from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path
from statistics import mean

try:
    import chess
except ImportError as exc:  # pragma: no cover
    raise SystemExit("Install python-chess first.") from exc


PHASES = ("opening", "middlegame", "endgame")
ASSET_NAMES = {
    "opening": "opening_positions.txt",
    "middlegame": "middlegame_positions.txt",
    "endgame": "endgame_positions.txt",
}


def main() -> int:
    args = parse_args()
    summary = {
        "candidate_store": str(args.candidate_store),
        "asset_dir": str(args.asset_dir),
        "phases": {},
    }
    metadata = load_candidate_metadata(args.candidate_store)

    for phase in PHASES:
        path = args.asset_dir / ASSET_NAMES[phase]
        fens = read_fens(path)
        phase_items = [metadata.get(fen) for fen in fens]
        matched = [item for item in phase_items if item is not None]
        evals = [int(item["cp_for_user"]) for item in matched]
        moves = [int(item["move_number"]) for item in matched]
        pieces = [int(item["piece_count"]) for item in matched]
        sources = collections.Counter(str(item["source_eval"]) for item in matched)

        summary["phases"][phase] = {
            "path": str(path),
            "count": len(fens),
            "size_bytes": path.stat().st_size if path.exists() else 0,
            "metadata_matches": len(matched),
            "eval_cp_range": [min(evals), max(evals)] if evals else None,
            "average_eval_cp": round(mean(evals), 1) if evals else None,
            "move_number_range": [min(moves), max(moves)] if moves else None,
            "average_move_number": round(mean(moves), 1) if moves else None,
            "piece_count_range": [min(pieces), max(pieces)] if pieces else None,
            "eval_sources": dict(sorted(sources.items())),
            "sample_fens": fens[:5],
        }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"summary={args.output}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--candidate-store",
        type=Path,
        default=Path("tools/position_factory/reports/full_candidates.jsonl"),
    )
    parser.add_argument(
        "--asset-dir",
        type=Path,
        default=Path("assets/positions"),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("tools/position_factory/reports/position_quality_summary.json"),
    )
    return parser.parse_args()


def load_candidate_metadata(path: Path) -> dict[str, dict[str, object]]:
    metadata: dict[str, dict[str, object]] = {}
    if not path.exists():
        return metadata
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            try:
                item = json.loads(line)
            except json.JSONDecodeError:
                continue
            fen = item.get("fen")
            if isinstance(fen, str):
                metadata[fen] = item
    return metadata


def read_fens(path: Path) -> list[str]:
    if not path.exists():
        return []
    fens: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        fen = line.strip()
        if not fen:
            continue
        try:
            board = chess.Board(fen)
        except ValueError:
            continue
        if board.is_valid():
            fens.append(fen)
    return fens


if __name__ == "__main__":
    raise SystemExit(main())
