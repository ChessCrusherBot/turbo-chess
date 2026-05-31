import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/chess/chess_board.dart';
import '../../../core/models/play_mode.dart';

class PlayComputerActiveGameSnapshot {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final DateTime startedAt;
  final DateTime updatedAt;
  final String startingFen;
  final String currentFen;
  final PieceColor userColor;
  final PieceColor engineColor;
  final String engineProfileId;
  final int engineDepth;
  final int engineSkill;
  final int engineMoveTimeMs;
  final int engineThreads;
  final int engineHashMb;
  final bool maxPowerEnabled;
  final bool boardFlipped;
  final String timeControlLabel;
  final bool timeControlEnabled;
  final bool noTimeControl;
  final int? timeControlBaseMs;
  final int timeControlIncrementMs;
  final int? whiteRemainingMs;
  final int? blackRemainingMs;
  final String? clockActiveSide;
  final bool clockRunning;
  final List<MoveRecord> moves;

  const PlayComputerActiveGameSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.startedAt,
    required this.updatedAt,
    required this.startingFen,
    required this.currentFen,
    required this.userColor,
    required this.engineColor,
    required this.engineProfileId,
    required this.engineDepth,
    required this.engineSkill,
    required this.engineMoveTimeMs,
    required this.engineThreads,
    required this.engineHashMb,
    required this.maxPowerEnabled,
    required this.boardFlipped,
    required this.timeControlLabel,
    required this.timeControlEnabled,
    required this.noTimeControl,
    required this.timeControlBaseMs,
    required this.timeControlIncrementMs,
    required this.whiteRemainingMs,
    required this.blackRemainingMs,
    required this.clockActiveSide,
    required this.clockRunning,
    required this.moves,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'startingFen': startingFen,
        'currentFen': currentFen,
        'userColor': userColor.name,
        'engineColor': engineColor.name,
        'engineProfileId': engineProfileId,
        'engineDepth': engineDepth,
        'engineSkill': engineSkill,
        'engineMoveTimeMs': engineMoveTimeMs,
        'engineThreads': engineThreads,
        'engineHashMb': engineHashMb,
        'maxPowerEnabled': maxPowerEnabled,
        'boardFlipped': boardFlipped,
        'timeControlLabel': timeControlLabel,
        'timeControlEnabled': timeControlEnabled,
        'noTimeControl': noTimeControl,
        'timeControlBaseMs': timeControlBaseMs,
        'timeControlIncrementMs': timeControlIncrementMs,
        'whiteRemainingMs': whiteRemainingMs,
        'blackRemainingMs': blackRemainingMs,
        'clockActiveSide': clockActiveSide,
        'clockRunning': clockRunning,
        'moves': moves.map((move) => move.toMap()).toList(),
      };

  factory PlayComputerActiveGameSnapshot.fromJson(Map<String, dynamic> json) {
    final movesRaw = json['moves'];
    final moves = <MoveRecord>[];
    if (movesRaw is List) {
      for (final item in movesRaw) {
        if (item is Map) {
          moves.add(MoveRecord.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return PlayComputerActiveGameSnapshot(
      schemaVersion:
          (json['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      startingFen: json['startingFen']?.toString() ?? '',
      currentFen: json['currentFen']?.toString() ?? '',
      userColor: _colorFromStorage(json['userColor']?.toString()),
      engineColor: _colorFromStorage(
        json['engineColor']?.toString(),
        fallback: PieceColor.black,
      ),
      engineProfileId: json['engineProfileId']?.toString() ?? 'strong',
      engineDepth: (json['engineDepth'] as num?)?.toInt() ?? 12,
      engineSkill: (json['engineSkill'] as num?)?.toInt() ?? 20,
      engineMoveTimeMs: (json['engineMoveTimeMs'] as num?)?.toInt() ?? 800,
      engineThreads: (json['engineThreads'] as num?)?.toInt() ?? 1,
      engineHashMb: (json['engineHashMb'] as num?)?.toInt() ?? 32,
      maxPowerEnabled: json['maxPowerEnabled'] == true,
      boardFlipped: json['boardFlipped'] == true,
      timeControlLabel:
          json['timeControlLabel']?.toString() ?? 'No Time Control',
      timeControlEnabled: json['timeControlEnabled'] == true,
      noTimeControl: json['noTimeControl'] != false,
      timeControlBaseMs: (json['timeControlBaseMs'] as num?)?.toInt(),
      timeControlIncrementMs:
          (json['timeControlIncrementMs'] as num?)?.toInt() ?? 0,
      whiteRemainingMs: (json['whiteRemainingMs'] as num?)?.toInt(),
      blackRemainingMs: (json['blackRemainingMs'] as num?)?.toInt(),
      clockActiveSide: json['clockActiveSide']?.toString(),
      clockRunning: json['clockRunning'] == true,
      moves: moves,
    );
  }

  bool get isUsable =>
      ChessBoard.isValidFen(startingFen) && ChessBoard.isValidFen(currentFen);

  static PieceColor _colorFromStorage(
    String? raw, {
    PieceColor fallback = PieceColor.white,
  }) {
    switch (raw?.toLowerCase()) {
      case 'black':
        return PieceColor.black;
      case 'white':
        return PieceColor.white;
      default:
        return fallback;
    }
  }
}

class PlayComputerActiveGameStore {
  static const String preferencesKey =
      'turbo_chess_active_play_computer_game_v1';

  const PlayComputerActiveGameStore();

  Future<bool> hasSavedSnapshotData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(preferencesKey);
    return raw != null && raw.isNotEmpty;
  }

  Future<PlayComputerActiveGameSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(preferencesKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final snapshot = PlayComputerActiveGameSnapshot.fromJson(decoded);
      return snapshot.isUsable ? snapshot : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PlayComputerActiveGameSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferencesKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(preferencesKey);
  }
}
