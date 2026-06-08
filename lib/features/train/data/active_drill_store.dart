import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/chess/chess_board.dart';
import '../../../core/models/play_mode.dart';
import '../../../core/positions/position_category.dart';

class ActiveDrillSnapshot {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final DateTime startedAt;
  final DateTime updatedAt;
  final PositionCategory category;
  final int positionIndex;
  final String startingFen;
  final String currentFen;
  final PieceColor userColor;
  final String engineProfileId;
  final bool boardFlipped;
  final List<MoveRecord> moves;

  const ActiveDrillSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.startedAt,
    required this.updatedAt,
    required this.category,
    required this.positionIndex,
    required this.startingFen,
    required this.currentFen,
    required this.userColor,
    required this.engineProfileId,
    required this.boardFlipped,
    required this.moves,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'category': category.id,
        'positionIndex': positionIndex,
        'startingFen': startingFen,
        'currentFen': currentFen,
        'userColor': userColor.name,
        'engineProfileId': engineProfileId,
        'boardFlipped': boardFlipped,
        'moves': moves.map((move) => move.toMap()).toList(),
      };

  factory ActiveDrillSnapshot.fromJson(Map<String, dynamic> json) {
    final movesRaw = json['moves'];
    final moves = <MoveRecord>[];
    if (movesRaw is List) {
      for (final item in movesRaw) {
        if (item is Map) {
          moves.add(MoveRecord.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ActiveDrillSnapshot(
      schemaVersion:
          (json['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      category: PositionCategory.fromId(json['category']?.toString()),
      positionIndex: (json['positionIndex'] as num?)?.toInt() ?? 0,
      startingFen: json['startingFen']?.toString() ?? '',
      currentFen: json['currentFen']?.toString() ?? '',
      userColor: _colorFromStorage(json['userColor']?.toString()),
      engineProfileId: json['engineProfileId']?.toString() ?? 'strong',
      boardFlipped: json['boardFlipped'] == true,
      moves: moves,
    );
  }

  bool get isUsable =>
      positionIndex >= 1 &&
      positionIndex <= 10000 &&
      ChessBoard.isValidFen(startingFen) &&
      ChessBoard.isValidFen(currentFen);

  static PieceColor _colorFromStorage(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'black':
        return PieceColor.black;
      case 'white':
      default:
        return PieceColor.white;
    }
  }
}

class ActiveDrillStore {
  static const String preferencesKey = 'turbo_chess_active_drill_v1';

  const ActiveDrillStore();

  Future<bool> hasSavedSnapshotData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(preferencesKey);
    return raw != null && raw.isNotEmpty;
  }

  Future<ActiveDrillSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(preferencesKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final snapshot = ActiveDrillSnapshot.fromJson(decoded);
      return snapshot.isUsable ? snapshot : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ActiveDrillSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferencesKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(preferencesKey);
  }
}
