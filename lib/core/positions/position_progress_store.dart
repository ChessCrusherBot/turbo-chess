import 'package:shared_preferences/shared_preferences.dart';

import 'position_category.dart';

class PositionProgressSnapshot {
  final int highestCompletedIndex;
  final int highestUnlockedIndex;
  final int lastPlayedIndex;
  final Set<int> completedIndexes;

  const PositionProgressSnapshot({
    required this.highestCompletedIndex,
    required this.highestUnlockedIndex,
    required this.lastPlayedIndex,
    required this.completedIndexes,
  });

  bool isCompleted(int positionIndex) {
    return completedIndexes.contains(positionIndex);
  }

  int get completedCount => completedIndexes.length.clamp(0, 10000).toInt();

  bool isUnlocked(int positionIndex, {required bool hasPremiumAccess}) {
    return PositionProgressStore.isUnlocked(
      positionIndex: positionIndex,
      highestUnlockedIndex: highestUnlockedIndex,
      hasPremiumAccess: hasPremiumAccess,
    );
  }
}

class PositionProgressStore {
  const PositionProgressStore();

  String highestCompletedKey(PositionCategory category) {
    return 'positions.v1.${category.id}.highest_completed_index';
  }

  String highestUnlockedKey(PositionCategory category) {
    return 'positions.v1.${category.id}.highest_unlocked_index';
  }

  String lastPlayedKey(PositionCategory category) {
    return 'positions.v1.${category.id}.last_played_index';
  }

  String completedSetKey(PositionCategory category) {
    return 'positions.v1.${category.id}.completed_indexes';
  }

  Future<PositionProgressSnapshot> snapshot(PositionCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final completedIndexes = _readCompletedIndexes(prefs, category);
    final storedCompleted = prefs.getInt(highestCompletedKey(category));
    if (completedIndexes.isEmpty &&
        storedCompleted != null &&
        storedCompleted > 0) {
      completedIndexes.addAll(
        Iterable<int>.generate(storedCompleted.clamp(0, 10000).toInt())
            .map((index) => index + 1),
      );
    }
    final highestCompleted = _clampIndex(
      storedCompleted ?? _highestCompletedFromSet(completedIndexes),
      min: 0,
    );
    final storedUnlocked = prefs.getInt(highestUnlockedKey(category));
    final highestUnlocked = _clampIndex(
      storedUnlocked ?? (highestCompleted + 1).clamp(1, 10000).toInt(),
      min: 1,
    );
    final lastPlayed = _clampIndex(
      prefs.getInt(lastPlayedKey(category)) ?? 1,
      min: 1,
    );

    return PositionProgressSnapshot(
      highestCompletedIndex: highestCompleted,
      highestUnlockedIndex: highestUnlocked,
      lastPlayedIndex: lastPlayed,
      completedIndexes: completedIndexes,
    );
  }

  Future<int> highestCompletedIndex(PositionCategory category) async {
    return (await snapshot(category)).highestCompletedIndex;
  }

  Future<int> highestUnlockedIndex(PositionCategory category) async {
    return (await snapshot(category)).highestUnlockedIndex;
  }

  Future<int> lastPlayedIndex(PositionCategory category) async {
    return (await snapshot(category)).lastPlayedIndex;
  }

  Future<void> setLastPlayed(
    PositionCategory category,
    int positionIndex,
  ) async {
    if (!_isValidIndex(positionIndex)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastPlayedKey(category), positionIndex);
  }

  Future<void> markCompleted(
    PositionCategory category,
    int positionIndex,
  ) async {
    if (!_isValidIndex(positionIndex)) return;

    final prefs = await SharedPreferences.getInstance();
    final completedIndexes = _readCompletedIndexes(prefs, category);
    completedIndexes.add(positionIndex);
    await _writeCompletedIndexes(prefs, category, completedIndexes);

    final currentCompleted = prefs.getInt(highestCompletedKey(category)) ?? 0;
    if (positionIndex > currentCompleted) {
      await prefs.setInt(highestCompletedKey(category), positionIndex);
    }

    final currentUnlocked = prefs.getInt(highestUnlockedKey(category)) ?? 1;
    if (positionIndex >= currentUnlocked) {
      await prefs.setInt(
        highestUnlockedKey(category),
        (positionIndex + 1).clamp(1, 10000).toInt(),
      );
    }
  }

  static bool isUnlocked({
    required int positionIndex,
    required int highestUnlockedIndex,
    required bool hasPremiumAccess,
  }) {
    return _isValidIndex(positionIndex);
  }

  Set<int> _readCompletedIndexes(
    SharedPreferences prefs,
    PositionCategory category,
  ) {
    final raw = prefs.getStringList(completedSetKey(category)) ?? const [];
    return raw
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .where(_isValidIndex)
        .toSet();
  }

  Future<void> _writeCompletedIndexes(
    SharedPreferences prefs,
    PositionCategory category,
    Set<int> completedIndexes,
  ) {
    final values = completedIndexes.toList()..sort();
    return prefs.setStringList(
      completedSetKey(category),
      values.map((value) => value.toString()).toList(growable: false),
    );
  }

  static int _highestCompletedFromSet(Set<int> completedIndexes) {
    if (completedIndexes.isEmpty) return 0;
    return completedIndexes.reduce((a, b) => a > b ? a : b);
  }

  static int _clampIndex(int value, {required int min}) {
    return value.clamp(min, 10000).toInt();
  }

  static bool _isValidIndex(int value) {
    return value >= 1 && value <= 10000;
  }
}
