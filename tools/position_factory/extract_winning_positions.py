#!/usr/bin/env python3
"""
Build Turbo Chess launch FEN assets from official Lichess standard PGNs.

The pipeline streams .zst PGNs, keeps only bounded candidate buckets in memory,
stores accepted candidates as JSONL for resume safety, and exports plain
one-FEN-per-line text assets only after each launch bucket is filled.
"""

from __future__ import annotations

import argparse
import collections
import dataclasses
import datetime as dt
import html.parser
import io
import json
import math
import os
import re
import shutil
import sys
import time
from pathlib import Path
from typing import Iterable

try:
    import chess
    import chess.engine
    import chess.pgn
except ImportError as exc:  # pragma: no cover - startup guard
    raise SystemExit(
        "Missing required package 'python-chess'. Install with:\n"
        "  python -m pip install python-chess zstandard tqdm requests"
    ) from exc

try:
    import requests
except ImportError as exc:  # pragma: no cover - startup guard
    raise SystemExit(
        "Missing required package 'requests'. Install with:\n"
        "  python -m pip install requests"
    ) from exc

try:
    import zstandard as zstd
except ImportError as exc:  # pragma: no cover - startup guard
    raise SystemExit(
        "Missing required package 'zstandard'. Install with:\n"
        "  python -m pip install zstandard"
    ) from exc

try:
    from tqdm import tqdm
except ImportError:  # pragma: no cover - progress bars are optional
    tqdm = None


PHASES = ("opening", "middlegame", "endgame")
DIFFICULTIES = ("beginner", "club", "intermediate", "advanced", "master")
OUTPUT_NAMES = {
    "opening": "opening_positions.txt",
    "middlegame": "middlegame_positions.txt",
    "endgame": "endgame_positions.txt",
}
DIFFICULTY_LABELS = {
    "beginner": "Beginner",
    "club": "Club",
    "intermediate": "Intermediate",
    "advanced": "Advanced",
    "master": "Master",
}
DATABASE_INDEX_URL = "https://database.lichess.org/standard/"
STANDARD_FILE_RE = re.compile(r"lichess_db_standard_rated_(\d{4}-\d{2})\.pgn\.zst$")
EVAL_COMMENT_RE = re.compile(r"\[%eval\s+([#]?-?\d+(?:\.\d+)?)\]")
STOCKFISH_DEFAULT = Path(
    r"C:\Users\lenovo\Desktop\CHESS_DRILL_FORGE\stockfish"
    r"\stockfish-windows-x86-64-avx2.exe"
)


@dataclasses.dataclass(frozen=True)
class DifficultySpec:
    name: str
    min_cp: int
    max_cp: int
    center_cp: int


DIFFICULTY_SPECS = {
    "beginner": DifficultySpec("beginner", 500, 900, 700),
    "club": DifficultySpec("club", 400, 700, 550),
    "intermediate": DifficultySpec("intermediate", 300, 600, 450),
    "advanced": DifficultySpec("advanced", 250, 500, 375),
    "master": DifficultySpec("master", 200, 400, 300),
}


@dataclasses.dataclass(frozen=True)
class EvalInfo:
    cp_white: int | None = None
    mate_white: int | None = None
    depth: int | None = None
    pv: tuple[chess.Move, ...] = ()
    source: str = "unknown"


@dataclasses.dataclass(frozen=True)
class Candidate:
    fen: str
    dedupe_key: str
    phase: str
    difficulty: str
    cp_for_user: int
    move_number: int
    piece_count: int
    non_pawn_piece_count: int
    legal_move_count: int
    remaining_plies: int | None
    source_file: str
    source_eval: str

    def sort_key_for(self, difficulty: str | None = None) -> tuple[int, int, int, int, str]:
        band = difficulty or self.difficulty
        spec = DIFFICULTY_SPECS[band]
        center_distance = abs(self.cp_for_user - spec.center_cp)
        remaining_penalty = (
            0 if self.remaining_plies is None else abs(self.remaining_plies - 50)
        )
        return (
            center_distance,
            remaining_penalty,
            -self.non_pawn_piece_count,
            -self.legal_move_count,
            self.dedupe_key,
        )

    def to_json(self) -> dict[str, object]:
        return dataclasses.asdict(self)

    @staticmethod
    def from_json(item: dict[str, object]) -> "Candidate":
        return Candidate(
            fen=str(item["fen"]),
            dedupe_key=str(item["dedupe_key"]),
            phase=str(item["phase"]),
            difficulty=str(item["difficulty"]),
            cp_for_user=int(item["cp_for_user"]),
            move_number=int(item["move_number"]),
            piece_count=int(item["piece_count"]),
            non_pawn_piece_count=int(item["non_pawn_piece_count"]),
            legal_move_count=int(item["legal_move_count"]),
            remaining_plies=(
                None
                if item.get("remaining_plies") is None
                else int(item["remaining_plies"])
            ),
            source_file=str(item["source_file"]),
            source_eval=str(item["source_eval"]),
        )


class Logger:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def write(self, message: str) -> None:
        stamp = dt.datetime.now(dt.UTC).isoformat(timespec="seconds")
        line = f"[{stamp}] {message}"
        print(line, flush=True)
        with self.path.open("a", encoding="utf-8") as handle:
            handle.write(line + "\n")


class CandidateBuckets:
    def __init__(self, max_candidates_per_bucket: int) -> None:
        self.max_candidates_per_bucket = max_candidates_per_bucket
        self._items: dict[str, dict[str, list[Candidate]]] = {
            phase: {difficulty: [] for difficulty in DIFFICULTIES}
            for phase in PHASES
        }
        self._seen: set[str] = set()
        self.duplicate_count = 0
        self.pruned_count = 0

    def add(self, candidate: Candidate) -> bool:
        if candidate.dedupe_key in self._seen:
            self.duplicate_count += 1
            return False

        bucket = self._items[candidate.phase][candidate.difficulty]
        bucket.append(candidate)
        self._seen.add(candidate.dedupe_key)

        if len(bucket) > self.max_candidates_per_bucket:
            bucket.sort(key=lambda item: item.sort_key_for())
            removed = bucket[self.max_candidates_per_bucket :]
            for item in removed:
                self._seen.discard(item.dedupe_key)
            del bucket[self.max_candidates_per_bucket :]
            self.pruned_count += len(removed)
        return True

    def counts(self) -> dict[str, dict[str, int]]:
        return {
            phase: {
                difficulty: len(self._items[phase][difficulty])
                for difficulty in DIFFICULTIES
            }
            for phase in PHASES
        }

    def flat_phase_candidates(self, phase: str) -> list[Candidate]:
        candidates: list[Candidate] = []
        for difficulty in DIFFICULTIES:
            candidates.extend(self._items[phase][difficulty])
        return candidates

    def total_count(self) -> int:
        return sum(
            len(self._items[phase][difficulty])
            for phase in PHASES
            for difficulty in DIFFICULTIES
        )

    def is_full(self, target_per_band: int) -> bool:
        counts = self.counts()
        return all(
            counts[phase][difficulty] >= target_per_band
            for phase in PHASES
            for difficulty in DIFFICULTIES
        )

    def phase_counts(self) -> dict[str, int]:
        return {
            phase: sum(len(self._items[phase][difficulty]) for difficulty in DIFFICULTIES)
            for phase in PHASES
        }

    def has_phase_targets(self, targets: dict[str, int]) -> bool:
        counts = self.phase_counts()
        return all(counts[phase] >= targets[phase] for phase in PHASES)

    def sample_phase(self, phase: str, target: int) -> list[Candidate]:
        candidates = sorted(
            self.flat_phase_candidates(phase),
            key=lambda item: item.sort_key_for(),
        )
        return candidates[:target]

    def export_phase(
        self,
        phase: str,
        target_per_band: int,
        global_output_seen: set[str],
        fill_report: list[str],
    ) -> list[str]:
        output: list[str] = []
        phase_used: set[str] = set()
        all_phase_candidates = self.flat_phase_candidates(phase)

        for difficulty in DIFFICULTIES:
            band_candidates = sorted(
                self._items[phase][difficulty],
                key=lambda item: item.sort_key_for(difficulty),
            )
            picked = self._pick_candidates(
                candidates=band_candidates,
                target=target_per_band,
                output=output,
                phase_used=phase_used,
                global_output_seen=global_output_seen,
            )

            if picked < target_per_band:
                needed = target_per_band - picked
                fallback_candidates = sorted(
                    all_phase_candidates,
                    key=lambda item: item.sort_key_for(difficulty),
                )
                fallback_picked = self._pick_candidates(
                    candidates=fallback_candidates,
                    target=needed,
                    output=output,
                    phase_used=phase_used,
                    global_output_seen=global_output_seen,
                )
                fill_report.append(
                    f"{phase}.{difficulty}: exact={picked}, "
                    f"fallback={fallback_picked}, target={target_per_band}"
                )

        return output

    def _pick_candidates(
        self,
        candidates: list[Candidate],
        target: int,
        output: list[str],
        phase_used: set[str],
        global_output_seen: set[str],
    ) -> int:
        picked = 0
        for candidate in candidates:
            if candidate.dedupe_key in phase_used:
                continue
            if candidate.dedupe_key in global_output_seen:
                continue
            output.append(candidate.fen)
            phase_used.add(candidate.dedupe_key)
            global_output_seen.add(candidate.dedupe_key)
            picked += 1
            if picked >= target:
                break
        return picked


class LinkCollector(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() != "a":
            return
        for key, value in attrs:
            if key.lower() == "href" and value:
                self.links.append(value)


def main() -> int:
    started_at = time.monotonic()
    args = parse_args()
    args.report_dir.mkdir(parents=True, exist_ok=True)
    logger = Logger(args.report_dir / "extraction_log.txt")

    if args.check_environment:
        return check_environment(args, logger)

    paths = list(args.pgn_zst)
    if args.download_latest or args.download_month:
        paths.extend(download_requested_months(args, logger))
    if args.download_only:
        logger.write("Download-only mode complete.")
        return 0

    if not paths:
        raise SystemExit(
            "No PGN source provided. Use --download-latest, --download-month, "
            "or --pgn-zst."
        )

    for path in paths:
        if not path.exists() or path.stat().st_size <= 0:
            raise SystemExit(f"PGN source is missing or empty: {path}")

    target_per_band = args.target_per_band
    if args.dry_run and not args.target_per_band_explicit:
        target_per_band = math.ceil(args.dry_run_target_per_phase / len(DIFFICULTIES))
    dry_run_targets = dry_run_phase_targets(args)

    buckets = CandidateBuckets(args.max_candidates_per_bucket)
    stats: collections.Counter[str] = collections.Counter()
    checkpoint = load_checkpoint(args.checkpoint) if args.resume else {}
    if args.resume:
        load_candidate_store(args.candidate_store, buckets, logger)

    engine = open_engine(args.stockfish, args, logger)
    candidate_writer = CandidateStoreWriter(args.candidate_store)
    try:
        for path in paths:
            scan_pgn_zst(
                path=path,
                args=args,
                target_per_band=target_per_band,
                dry_run_targets=dry_run_targets,
                buckets=buckets,
                stats=stats,
                checkpoint=checkpoint,
                logger=logger,
                candidate_writer=candidate_writer,
                engine=engine,
            )
            if args.stop_when_full and extraction_targets_met(
                args=args,
                buckets=buckets,
                target_per_band=target_per_band,
                dry_run_targets=dry_run_targets,
            ):
                logger.write("All target buckets are full; stopping early.")
                break
    finally:
        candidate_writer.close()
        if engine is not None:
            engine.quit()

    elapsed = time.monotonic() - started_at
    write_report(
        args=args,
        buckets=buckets,
        stats=stats,
        elapsed_seconds=elapsed,
        target_per_band=target_per_band,
        dry_run_targets=dry_run_targets,
        logger=logger,
    )

    print_counts(buckets.counts())
    if args.dry_run:
        write_dry_run_samples(
            buckets=buckets,
            output_dir=args.output_dir,
            targets=dry_run_targets,
            logger=logger,
        )
        return 0

    write_outputs(
        buckets=buckets,
        output_dir=args.output_dir,
        target_per_band=target_per_band,
        report_dir=args.report_dir,
        logger=logger,
    )
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract long-form winning conversion FENs for Turbo Chess.",
    )
    parser.add_argument("--pgn-zst", nargs="*", type=Path, default=[])
    parser.add_argument("--download-latest", action="store_true")
    parser.add_argument("--download-only", action="store_true")
    parser.add_argument(
        "--download-month",
        nargs="*",
        default=[],
        help="One or more YYYY-MM Lichess standard months to download/use.",
    )
    parser.add_argument(
        "--database-index-url",
        default=DATABASE_INDEX_URL,
        help="Official Lichess standard database index URL.",
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=default_data_dir(),
        help="Directory for downloaded .pgn.zst files.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("assets/positions"),
        help="Directory receiving opening/middlegame/endgame position files.",
    )
    parser.add_argument(
        "--report-dir",
        type=Path,
        default=Path("tools/position_factory/reports"),
    )
    parser.add_argument(
        "--report",
        type=Path,
        help="Exact report path. Defaults inside --report-dir.",
    )
    parser.add_argument(
        "--checkpoint",
        type=Path,
        default=Path("tools/position_factory/reports/checkpoint.json"),
    )
    parser.add_argument(
        "--candidate-store",
        type=Path,
        default=Path("tools/position_factory/reports/candidates.jsonl"),
    )
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--target-per-band", type=int, default=2000)
    parser.add_argument("--dry-run-target-per-phase", type=int, default=100)
    parser.add_argument("--target-opening", type=int)
    parser.add_argument("--target-middlegame", type=int)
    parser.add_argument("--target-endgame", type=int)
    parser.add_argument("--max-candidates-per-bucket", type=int, default=7000)
    parser.add_argument("--max-games", type=int, default=0)
    parser.add_argument("--max-engine-analyses", type=int, default=0)
    parser.add_argument("--max-engine-positions-per-game", type=int, default=4)
    parser.add_argument("--candidate-ply-stride", type=int, default=4)
    parser.add_argument("--checkpoint-every", type=int, default=5000)
    parser.add_argument("--min-average-elo", type=int, default=1600)
    parser.add_argument("--min-game-plies", type=int, default=60)
    parser.add_argument("--min-remaining-plies", type=int, default=40)
    parser.add_argument("--reject-mate-plies", type=int, default=10)
    parser.add_argument("--min-depth", type=int, default=0)
    parser.add_argument("--stockfish", type=Path, default=STOCKFISH_DEFAULT)
    parser.add_argument("--engine-depth", type=int, default=8)
    parser.add_argument("--engine-time", type=float, default=0.03)
    parser.add_argument("--verify-pgn-evals", action="store_true")
    parser.add_argument("--no-engine-for-missing-evals", action="store_true")
    parser.add_argument("--include-non-decisive-games", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--stop-when-full", action="store_true", default=True)
    parser.add_argument("--check-environment", action="store_true")
    args = parser.parse_args()
    args.target_per_band_explicit = "--target-per-band" in sys.argv
    return args


def default_data_dir() -> Path:
    d_root = Path("D:/")
    if d_root.exists():
        return Path("D:/lichess")
    return Path("C:/lichess")


def dry_run_phase_targets(args: argparse.Namespace) -> dict[str, int]:
    default_target = int(args.dry_run_target_per_phase)
    return {
        "opening": int(args.target_opening or default_target),
        "middlegame": int(args.target_middlegame or default_target),
        "endgame": int(args.target_endgame or default_target),
    }


def extraction_targets_met(
    args: argparse.Namespace,
    buckets: CandidateBuckets,
    target_per_band: int,
    dry_run_targets: dict[str, int],
) -> bool:
    if args.dry_run:
        return buckets.has_phase_targets(dry_run_targets)
    return buckets.is_full(target_per_band)


def check_environment(args: argparse.Namespace, logger: Logger) -> int:
    logger.write(f"python={sys.version.split()[0]}")
    logger.write(f"python-chess={getattr(chess, '__version__', 'installed')}")
    logger.write("zstandard=installed")
    logger.write(f"requests={getattr(requests, '__version__', 'installed')}")
    logger.write(f"tqdm={'installed' if tqdm is not None else 'missing'}")
    logger.write(f"cwd={Path.cwd()}")
    logger.write(f"data_dir={args.data_dir}")

    usage = shutil.disk_usage(Path.cwd())
    logger.write(f"free_disk_bytes={usage.free}")

    if args.stockfish:
        logger.write(f"stockfish_path={args.stockfish}")
        logger.write(f"stockfish_exists={args.stockfish.exists()}")
    else:
        logger.write("stockfish_path=not_provided")
    return 0


def download_requested_months(args: argparse.Namespace, logger: Logger) -> list[Path]:
    args.data_dir.mkdir(parents=True, exist_ok=True)
    months = list(args.download_month)
    if args.download_latest:
        latest = latest_standard_month(args.database_index_url, logger)
        if latest not in months:
            months.insert(0, latest)

    paths: list[Path] = []
    for month in months:
        if not re.fullmatch(r"\d{4}-\d{2}", month):
            raise SystemExit(f"Invalid Lichess month '{month}'. Use YYYY-MM.")
        name = f"lichess_db_standard_rated_{month}.pgn.zst"
        url = args.database_index_url.rstrip("/") + "/" + name
        target = args.data_dir / name
        download_with_resume(url, target, logger)
        paths.append(target)
    return paths


def latest_standard_month(index_url: str, logger: Logger) -> str:
    logger.write(f"Fetching Lichess standard index: {index_url}")
    response = requests.get(index_url, timeout=60)
    response.raise_for_status()

    parser = LinkCollector()
    parser.feed(response.text)
    months: list[str] = []
    for link in parser.links:
        name = Path(link).name
        match = STANDARD_FILE_RE.fullmatch(name)
        if match:
            months.append(match.group(1))

    if not months:
        raise SystemExit("No Lichess standard PGN months found in index.")
    latest = sorted(set(months))[-1]
    logger.write(f"Latest available Lichess standard month: {latest}")
    return latest


def download_with_resume(url: str, target: Path, logger: Logger) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    existing = target.stat().st_size if target.exists() else 0
    remote_size = remote_content_length(url)

    if remote_size and existing == remote_size:
        logger.write(f"Using existing complete download: {target} ({existing} bytes)")
        return

    if remote_size:
        free = shutil.disk_usage(target.parent).free
        needed = max(remote_size - existing, 0)
        if free < needed + 2_000_000_000:
            raise SystemExit(
                f"Not enough free disk for {target}. Need about {needed} bytes "
                f"plus safety margin, free={free}."
            )

    for attempt in range(1, 3):
        try:
            headers = {"Range": f"bytes={existing}-"} if existing else {}
            mode = "ab" if existing else "wb"
            logger.write(
                f"Downloading {url} to {target} "
                f"(attempt {attempt}, resume_at={existing})"
            )
            with requests.get(url, headers=headers, stream=True, timeout=120) as response:
                if response.status_code == 416 and remote_size and existing == remote_size:
                    logger.write(f"Download already complete: {target}")
                    return
                response.raise_for_status()
                total = remote_size if remote_size else None
                progress = make_progress(
                    total=total,
                    initial=existing,
                    desc=f"Download {target.name}",
                    unit="B",
                    unit_scale=True,
                )
                with target.open(mode) as handle:
                    for chunk in response.iter_content(chunk_size=1024 * 1024):
                        if not chunk:
                            continue
                        handle.write(chunk)
                        if progress is not None:
                            progress.update(len(chunk))
                if progress is not None:
                    progress.close()
            final_size = target.stat().st_size
            if remote_size and final_size != remote_size:
                raise RuntimeError(
                    f"Download incomplete: {final_size}/{remote_size} bytes"
                )
            if final_size <= 0:
                raise RuntimeError("Downloaded file is empty")
            logger.write(f"Download ready: {target} ({final_size} bytes)")
            return
        except Exception as exc:  # noqa: BLE001 - log exact retry reason
            logger.write(f"Download attempt {attempt} failed: {exc!r}")
            existing = target.stat().st_size if target.exists() else 0
            if attempt >= 2:
                raise
            time.sleep(3)


def remote_content_length(url: str) -> int | None:
    try:
        response = requests.head(url, allow_redirects=True, timeout=60)
        response.raise_for_status()
        raw = response.headers.get("Content-Length")
        return int(raw) if raw else None
    except Exception:
        return None


class CandidateStoreWriter:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._handle = self.path.open("a", encoding="utf-8")
        self._pending = 0

    def write(self, candidate: Candidate) -> None:
        self._handle.write(json.dumps(candidate.to_json(), separators=(",", ":")) + "\n")
        self._pending += 1
        if self._pending >= 100:
            self.flush()

    def flush(self) -> None:
        self._handle.flush()
        os.fsync(self._handle.fileno())
        self._pending = 0

    def close(self) -> None:
        self.flush()
        self._handle.close()


def load_candidate_store(path: Path, buckets: CandidateBuckets, logger: Logger) -> None:
    if not path.exists():
        logger.write(f"No candidate store to resume: {path}")
        return

    loaded = 0
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            try:
                candidate = Candidate.from_json(json.loads(line))
            except Exception:
                continue
            if buckets.add(candidate):
                loaded += 1
    logger.write(f"Loaded {loaded} resume candidates from {path}")


def load_checkpoint(path: Path) -> dict[str, object]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def save_checkpoint(
    path: Path,
    source: Path,
    game_count: int,
    position_count: int,
    engine_analyses: int,
    stats: collections.Counter[str],
    buckets: CandidateBuckets,
    logger: Logger,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    checkpoint = load_checkpoint(path)
    sources = checkpoint.get("sources")
    if not isinstance(sources, dict):
        sources = {}
    sources[str(source)] = {
        "games_scanned": game_count,
        "positions_considered": position_count,
        "engine_analyses": engine_analyses,
        "updated_at": dt.datetime.now(dt.UTC).isoformat(timespec="seconds"),
    }
    checkpoint = {
        "sources": sources,
        "stats": dict(stats),
        "bucket_counts": buckets.counts(),
        "candidate_count": buckets.total_count(),
    }
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(checkpoint, indent=2, sort_keys=True), encoding="utf-8")
    tmp.replace(path)
    logger.write(
        f"checkpoint source={source.name} games={game_count} "
        f"positions={position_count} candidates={buckets.total_count()}"
    )


def open_engine(
    stockfish_path: Path | None,
    args: argparse.Namespace,
    logger: Logger,
) -> chess.engine.SimpleEngine | None:
    if stockfish_path is None or args.no_engine_for_missing_evals:
        logger.write("Stockfish verification disabled for missing evals.")
        return None
    if not stockfish_path.exists():
        logger.write(f"Stockfish path does not exist: {stockfish_path}")
        return None

    logger.write(
        f"Starting Stockfish: {stockfish_path} "
        f"depth={args.engine_depth} time={args.engine_time}"
    )
    engine = chess.engine.SimpleEngine.popen_uci(str(stockfish_path))
    try:
        engine.configure({"Threads": 1, "Hash": 128})
    except chess.engine.EngineError:
        logger.write("Stockfish did not accept Threads/Hash options; continuing.")
    return engine


def scan_pgn_zst(
    path: Path,
    args: argparse.Namespace,
    target_per_band: int,
    dry_run_targets: dict[str, int],
    buckets: CandidateBuckets,
    stats: collections.Counter[str],
    checkpoint: dict[str, object],
    logger: Logger,
    candidate_writer: CandidateStoreWriter,
    engine: chess.engine.SimpleEngine | None,
) -> None:
    skip_games = resume_game_count(path, checkpoint) if args.resume else 0
    game_count = 0
    position_count = 0
    engine_analyses = 0
    logger.write(f"Scanning PGN zst: {path} skip_games={skip_games}")

    iterator = iter(int, 1)
    progress = None
    if tqdm is not None:
        progress = tqdm(iterator, desc=f"PGN {path.name}", unit="game")
        iterable = progress
    else:
        iterable = iterator

    with path.open("rb") as raw:
        reader = zstd.ZstdDecompressor().stream_reader(raw)
        stream = io.TextIOWrapper(reader, encoding="utf-8", errors="replace")

        for _ in iterable:
            game = chess.pgn.read_game(stream)
            if game is None:
                break

            game_count += 1
            if game_count <= skip_games:
                continue
            if args.max_games and (game_count - skip_games) > args.max_games:
                break

            if not game_is_usable(game, args, stats):
                continue

            moves = list(game.mainline_moves())
            if len(moves) < args.min_game_plies:
                stats["reject_game_short"] += 1
                continue

            per_game_engine_uses = 0
            board = game.board()
            node = game
            ply_index = 0
            while node.variations:
                node = node.variation(0)
                board.push(node.move)
                ply_index += 1

                remaining_plies = len(moves) - ply_index
                if remaining_plies < args.min_remaining_plies:
                    stats["reject_too_close_to_game_end"] += 1
                    continue

                phase = classify_phase(board)
                if phase is None:
                    stats["reject_phase"] += 1
                    continue

                eval_info = parse_eval_comment(node.comment)
                if eval_info is not None:
                    stats["pgn_evals_used"] += 1
                    if args.verify_pgn_evals and engine is not None:
                        verified = analyze_with_engine(board, engine, args)
                        if verified is not None:
                            eval_info = verified
                            engine_analyses += 1
                elif engine is not None and should_engine_analyze(
                    ply_index=ply_index,
                    per_game_engine_uses=per_game_engine_uses,
                    engine_analyses=engine_analyses,
                    args=args,
                ):
                    eval_info = analyze_with_engine(board, engine, args)
                    per_game_engine_uses += 1
                    engine_analyses += 1
                    stats["stockfish_evals_used"] += 1

                if eval_info is None:
                    stats["reject_no_eval"] += 1
                    continue

                position_count += 1
                candidate, reason = build_candidate(
                    board=board,
                    phase=phase,
                    eval_info=eval_info,
                    remaining_plies=remaining_plies,
                    source=str(path),
                    args=args,
                )
                if candidate is None:
                    stats[f"reject_{reason}"] += 1
                    continue

                if buckets.add(candidate):
                    stats["accepted"] += 1
                    candidate_writer.write(candidate)
                else:
                    stats["duplicate"] += 1

                if args.stop_when_full and extraction_targets_met(
                    args=args,
                    buckets=buckets,
                    target_per_band=target_per_band,
                    dry_run_targets=dry_run_targets,
                ):
                    save_checkpoint(
                        args.checkpoint,
                        path,
                        game_count,
                        position_count,
                        engine_analyses,
                        stats,
                        buckets,
                        logger,
                    )
                    return

            if args.checkpoint_every and game_count % args.checkpoint_every == 0:
                candidate_writer.flush()
                save_checkpoint(
                    args.checkpoint,
                    path,
                    game_count,
                    position_count,
                    engine_analyses,
                    stats,
                    buckets,
                    logger,
                )

    if progress is not None:
        progress.close()
    save_checkpoint(
        args.checkpoint,
        path,
        game_count,
        position_count,
        engine_analyses,
        stats,
        buckets,
        logger,
    )


def resume_game_count(path: Path, checkpoint: dict[str, object]) -> int:
    sources = checkpoint.get("sources")
    if not isinstance(sources, dict):
        return 0
    source = sources.get(str(path))
    if not isinstance(source, dict):
        return 0
    try:
        return int(source.get("games_scanned", 0))
    except (TypeError, ValueError):
        return 0


def game_is_usable(
    game: chess.pgn.Game,
    args: argparse.Namespace,
    stats: collections.Counter[str],
) -> bool:
    variant = game.headers.get("Variant", "Standard")
    if variant not in ("", "Standard"):
        stats["reject_game_variant"] += 1
        return False

    if game.headers.get("WhiteTitle") == "BOT" or game.headers.get("BlackTitle") == "BOT":
        stats["reject_game_bot"] += 1
        return False

    result = game.headers.get("Result", "")
    if not args.include_non_decisive_games and result not in ("1-0", "0-1"):
        stats["reject_game_non_decisive"] += 1
        return False

    white_elo = parse_int(game.headers.get("WhiteElo"))
    black_elo = parse_int(game.headers.get("BlackElo"))
    if white_elo is None or black_elo is None:
        stats["reject_game_missing_elo"] += 1
        return False
    if (white_elo + black_elo) / 2 < args.min_average_elo:
        stats["reject_game_low_elo"] += 1
        return False
    return True


def parse_int(value: str | None) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except ValueError:
        return None


def parse_eval_comment(comment: str) -> EvalInfo | None:
    match = EVAL_COMMENT_RE.search(comment)
    if not match:
        return None

    raw = match.group(1)
    if raw.startswith("#"):
        try:
            return EvalInfo(mate_white=int(raw[1:]), source="pgn")
        except ValueError:
            return None

    try:
        return EvalInfo(cp_white=round(float(raw) * 100), source="pgn")
    except ValueError:
        return None


def should_engine_analyze(
    ply_index: int,
    per_game_engine_uses: int,
    engine_analyses: int,
    args: argparse.Namespace,
) -> bool:
    if args.max_engine_analyses and engine_analyses >= args.max_engine_analyses:
        return False
    if per_game_engine_uses >= args.max_engine_positions_per_game:
        return False
    stride = max(args.candidate_ply_stride, 1)
    return ply_index % stride == 0


def analyze_with_engine(
    board: chess.Board,
    engine: chess.engine.SimpleEngine,
    args: argparse.Namespace,
) -> EvalInfo | None:
    limit = chess.engine.Limit(depth=args.engine_depth, time=args.engine_time)
    try:
        result = engine.analyse(board, limit, multipv=1)
    except (chess.engine.EngineError, chess.engine.EngineTerminatedError):
        return None
    if isinstance(result, list):
        if not result:
            return None
        result = result[0]

    score = result.get("score")
    if score is None:
        return None
    white_score = score.white()
    pv = tuple(result.get("pv", ()))
    depth = result.get("depth")
    if not isinstance(depth, int):
        depth = args.engine_depth

    if white_score.is_mate():
        mate = white_score.mate()
        return EvalInfo(mate_white=mate, depth=depth, pv=pv, source="stockfish")
    cp = white_score.score()
    if cp is None:
        return None
    return EvalInfo(cp_white=cp, depth=depth, pv=pv, source="stockfish")


def classify_phase(board: chess.Board) -> str | None:
    move = board.fullmove_number
    piece_count = len(board.piece_map())
    non_pawn = non_pawn_piece_count(board)

    if move >= 35 and 4 <= piece_count <= 14 and non_pawn <= 6:
        return "endgame"
    if 6 <= move <= 18 and piece_count >= 24 and non_pawn >= 10:
        return "opening"
    if 15 <= move <= 40 and piece_count >= 14 and non_pawn >= 6:
        return "middlegame"
    return None


def non_pawn_piece_count(board: chess.Board) -> int:
    return sum(
        1
        for piece in board.piece_map().values()
        if piece.piece_type not in (chess.PAWN, chess.KING)
    )


def build_candidate(
    board: chess.Board,
    phase: str,
    eval_info: EvalInfo,
    remaining_plies: int | None,
    source: str,
    args: argparse.Namespace,
) -> tuple[Candidate | None, str]:
    ok, reason = basic_position_filter(board, phase, args)
    if not ok:
        return None, reason
    if eval_info.depth is not None and eval_info.depth < args.min_depth:
        return None, "low_depth"
    if eval_info.mate_white is not None:
        if abs(eval_info.mate_white) <= args.reject_mate_plies:
            return None, "short_forced_mate"
        return None, "mate_score"
    if eval_info.cp_white is None:
        return None, "no_cp"

    cp_for_user = eval_info.cp_white if board.turn == chess.WHITE else -eval_info.cp_white
    difficulty = difficulty_for_cp(cp_for_user)
    if difficulty is None:
        return None, "eval_out_of_range"
    if pv_reaches_checkmate(board, eval_info.pv, args.reject_mate_plies):
        return None, "pv_short_mate"

    fen = board.fen(en_passant="legal")
    return (
        Candidate(
            fen=fen,
            dedupe_key=board.epd(en_passant="legal"),
            phase=phase,
            difficulty=difficulty,
            cp_for_user=cp_for_user,
            move_number=board.fullmove_number,
            piece_count=len(board.piece_map()),
            non_pawn_piece_count=non_pawn_piece_count(board),
            legal_move_count=board.legal_moves.count(),
            remaining_plies=remaining_plies,
            source_file=source,
            source_eval=eval_info.source,
        ),
        "accepted",
    )


def difficulty_for_cp(cp_for_user: int) -> str | None:
    eligible: list[str] = []
    for name in DIFFICULTIES:
        spec = DIFFICULTY_SPECS[name]
        if spec.min_cp <= cp_for_user <= spec.max_cp:
            eligible.append(name)
    if eligible:
        return min(
            eligible,
            key=lambda name: abs(cp_for_user - DIFFICULTY_SPECS[name].center_cp),
        )

    if cp_for_user > DIFFICULTY_SPECS["beginner"].max_cp:
        return "beginner"
    return None


def basic_position_filter(
    board: chess.Board,
    phase: str,
    args: argparse.Namespace,
) -> tuple[bool, str]:
    if not board.is_valid():
        return False, "invalid_fen"
    if board.is_checkmate():
        return False, "already_checkmate"
    if board.is_stalemate():
        return False, "stalemate"
    if board.is_insufficient_material():
        return False, "insufficient_material"
    if board.halfmove_clock >= 80:
        return False, "halfmove_clock"
    if not side_has_mating_material(board, board.turn):
        return False, "no_mating_material_for_user"
    if board_has_mate_in_one(board):
        return False, "mate_in_one"

    legal_count = board.legal_moves.count()
    min_legal = {"opening": 12, "middlegame": 8, "endgame": 4}[phase]
    if legal_count < min_legal:
        return False, "too_few_legal_moves"
    return True, "ok"


def side_has_mating_material(board: chess.Board, color: chess.Color) -> bool:
    pieces = board.piece_map().values()
    own_types = [piece.piece_type for piece in pieces if piece.color == color]
    if chess.QUEEN in own_types or chess.ROOK in own_types or chess.PAWN in own_types:
        return True
    bishops = own_types.count(chess.BISHOP)
    knights = own_types.count(chess.KNIGHT)
    return bishops >= 2 or (bishops >= 1 and knights >= 1) or bishops + knights >= 3


def board_has_mate_in_one(board: chess.Board) -> bool:
    probe = board.copy(stack=False)
    for move in board.legal_moves:
        probe.push(move)
        is_mate = probe.is_checkmate()
        probe.pop()
        if is_mate:
            return True
    return False


def pv_reaches_checkmate(
    board: chess.Board,
    pv: tuple[chess.Move, ...],
    max_plies: int,
) -> bool:
    if not pv:
        return False
    probe = board.copy(stack=False)
    for ply, move in enumerate(pv, start=1):
        if move not in probe.legal_moves:
            return False
        probe.push(move)
        if probe.is_checkmate() and ply <= max_plies:
            return True
        if ply >= max_plies:
            return False
    return False


def make_progress(
    total: int | None,
    initial: int,
    desc: str,
    unit: str,
    unit_scale: bool = False,
):
    if tqdm is None:
        return None
    return tqdm(
        total=total,
        initial=initial,
        desc=desc,
        unit=unit,
        unit_scale=unit_scale,
        dynamic_ncols=True,
    )


def print_counts(counts: dict[str, dict[str, int]]) -> None:
    for phase in PHASES:
        parts = [f"{difficulty}={counts[phase][difficulty]}" for difficulty in DIFFICULTIES]
        print(f"{phase}: " + ", ".join(parts))


def write_report(
    args: argparse.Namespace,
    buckets: CandidateBuckets,
    stats: collections.Counter[str],
    elapsed_seconds: float,
    target_per_band: int,
    dry_run_targets: dict[str, int],
    logger: Logger,
) -> None:
    report_name = "dry_run_report.txt" if args.dry_run else "full_extraction_report.txt"
    path = args.report or (args.report_dir / report_name)
    path.parent.mkdir(parents=True, exist_ok=True)
    counts = buckets.counts()
    phase_counts = buckets.phase_counts()
    accepted = stats.get("accepted", 0)
    games_scanned = sum_source_games(args.checkpoint)
    avg_eval = average_eval_from_buckets(buckets)

    lines = [
        "Turbo Chess Position Factory Report",
        f"created_utc: {dt.datetime.now(dt.UTC).isoformat(timespec='seconds')}",
        f"elapsed_seconds: {elapsed_seconds:.1f}",
        f"target_per_band: {target_per_band}",
        f"dry_run_targets: {dry_run_targets if args.dry_run else 'n/a'}",
        f"games_scanned_checkpoint_total: {games_scanned}",
        f"accepted_positions: {accepted}",
        f"duplicate_count: {stats.get('duplicate', 0) + buckets.duplicate_count}",
        f"pruned_count: {buckets.pruned_count}",
        f"average_eval_cp_for_user: {avg_eval:.1f}" if avg_eval is not None else "average_eval_cp_for_user: n/a",
        "",
        "Bucket counts:",
    ]
    for phase in PHASES:
        lines.append(
            f"- {phase}: "
            + ", ".join(f"{difficulty}={counts[phase][difficulty]}" for difficulty in DIFFICULTIES)
            + f", total={phase_counts[phase]}"
        )

    lines.extend(["", "Phase quality metrics:"])
    for phase in PHASES:
        lines.extend(phase_metric_lines(phase, buckets.sample_phase(phase, dry_run_targets[phase] if args.dry_run else 50)))

    lines.extend(["", "Rejected/processing counts:"])
    for key, value in sorted(stats.items()):
        lines.append(f"- {key}: {value}")

    lines.extend(["", "Sample FENs:"])
    for phase in PHASES:
        samples = sorted(buckets.flat_phase_candidates(phase), key=lambda item: item.sort_key_for())[:5]
        lines.append(f"{phase}:")
        for sample in samples:
            lines.append(f"- {sample.fen} | cp={sample.cp_for_user} | {sample.source_eval}")

    lines.extend(["", "Expected full-run feasibility:"])
    if args.dry_run:
        per_game = accepted / max(games_scanned, 1)
        needed = target_per_band * len(DIFFICULTIES) * len(PHASES)
        estimated_games = math.ceil(needed / per_game) if per_game > 0 else "unknown"
        lines.append(f"- accepted_per_scanned_game: {per_game:.4f}")
        lines.append(f"- estimated_games_for_current_target: {estimated_games}")
        lines.append(
            "- Feasibility depends on endgame bucket fill rate; widen source months "
            "before loosening quality filters."
        )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    logger.write(f"Wrote report: {path}")


def sum_source_games(checkpoint_path: Path) -> int:
    checkpoint = load_checkpoint(checkpoint_path)
    sources = checkpoint.get("sources")
    if not isinstance(sources, dict):
        return 0
    total = 0
    for source in sources.values():
        if isinstance(source, dict):
            try:
                total += int(source.get("games_scanned", 0))
            except (TypeError, ValueError):
                pass
    return total


def average_eval_from_buckets(buckets: CandidateBuckets) -> float | None:
    values = [
        candidate.cp_for_user
        for phase in PHASES
        for candidate in buckets.flat_phase_candidates(phase)
    ]
    if not values:
        return None
    return sum(values) / len(values)


def phase_metric_lines(phase: str, candidates: list[Candidate]) -> list[str]:
    if not candidates:
        return [
            f"{phase}:",
            "- count: 0",
            "- average_move_number: n/a",
            "- piece_count_range: n/a",
            "- eval_cp_range: n/a",
        ]

    move_numbers = [candidate.move_number for candidate in candidates]
    piece_counts = [candidate.piece_count for candidate in candidates]
    evals = [candidate.cp_for_user for candidate in candidates]
    eval_sources = collections.Counter(candidate.source_eval for candidate in candidates)
    return [
        f"{phase}:",
        f"- count: {len(candidates)}",
        f"- average_move_number: {sum(move_numbers) / len(move_numbers):.1f}",
        f"- piece_count_range: {min(piece_counts)}-{max(piece_counts)}",
        f"- eval_cp_range: {min(evals)}-{max(evals)}",
        "- eval_sources: "
        + ", ".join(f"{source}={count}" for source, count in sorted(eval_sources.items())),
    ]


def write_dry_run_samples(
    buckets: CandidateBuckets,
    output_dir: Path,
    targets: dict[str, int],
    logger: Logger,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    global_seen: set[str] = set()

    for phase in PHASES:
        selected: list[Candidate] = []
        for candidate in buckets.sample_phase(phase, targets[phase]):
            if candidate.dedupe_key in global_seen:
                continue
            selected.append(candidate)
            global_seen.add(candidate.dedupe_key)
            if len(selected) >= targets[phase]:
                break

        path = output_dir / f"{phase}_sample.txt"
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text(
            "\n".join(candidate.fen for candidate in selected)
            + ("\n" if selected else ""),
            encoding="utf-8",
        )
        tmp.replace(path)
        logger.write(f"wrote dry-run sample {path} ({len(selected)}/{targets[phase]})")


def write_outputs(
    buckets: CandidateBuckets,
    output_dir: Path,
    target_per_band: int,
    report_dir: Path,
    logger: Logger,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    expected = target_per_band * len(DIFFICULTIES)
    global_seen: set[str] = set()
    fill_report: list[str] = []
    outputs: dict[str, list[str]] = {}

    for phase in PHASES:
        fens = buckets.export_phase(phase, target_per_band, global_seen, fill_report)
        outputs[phase] = fens
        if len(fens) < expected:
            shortage = expected - len(fens)
            details = "\n".join(fill_report)
            raise SystemExit(
                f"Not enough {phase} candidates for exact export: "
                f"{len(fens)}/{expected}, shortage={shortage}.\n{details}"
            )

    for phase, fens in outputs.items():
        path = output_dir / OUTPUT_NAMES[phase]
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text("\n".join(fens) + "\n", encoding="utf-8")
        tmp.replace(path)
        logger.write(f"wrote {path} ({len(fens)}/{expected})")

    if fill_report:
        (report_dir / "difficulty_fill_report.txt").write_text(
            "\n".join(fill_report) + "\n",
            encoding="utf-8",
        )


if __name__ == "__main__":
    raise SystemExit(main())
