import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/play_computer_game_record.dart';

class PlayComputerHistoryStore {
  static const String preferencesKey = 'turbo_chess_play_computer_history_v1';
  static const int maxRecords = 100;

  const PlayComputerHistoryStore();

  Future<List<PlayComputerGameRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(preferencesKey) ?? const <String>[];
    final records = <PlayComputerGameRecord>[];

    for (final raw in rawItems) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        final record = PlayComputerGameRecord.fromJson(decoded);
        if (record.id.isEmpty || record.startingFen.isEmpty) continue;
        records.add(record);
      } catch (_) {
        continue;
      }
    }

    records.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return records.take(maxRecords).toList(growable: false);
  }

  Future<void> saveRecord(PlayComputerGameRecord record) async {
    final records = await load();
    final updated = <PlayComputerGameRecord>[
      record,
      for (final existing in records)
        if (existing.id != record.id) existing,
    ].take(maxRecords).toList(growable: false);
    await _save(updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(preferencesKey);
  }

  Future<void> _save(List<PlayComputerGameRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      preferencesKey,
      records.map((record) => jsonEncode(record.toJson())).toList(),
    );
  }
}
