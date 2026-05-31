import 'package:flutter/services.dart';

import 'position_category.dart';
import 'position_difficulty.dart';

class PositionFenRepository {
  final AssetBundle bundle;
  final Map<PositionCategory, List<String>> _moduleCache = {};

  PositionFenRepository({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  Future<void> initialize() async {}

  Future<void> loadModule(PositionCategory category) async {
    await _linesFor(category);
  }

  Future<int> availableCount(PositionCategory category) async {
    return (await _linesFor(category)).length;
  }

  int getPositionCount(PositionCategory category) {
    return _moduleCache[category]?.length ?? 0;
  }

  Future<String> getFen(PositionCategory category, int positionIndex) {
    return loadFen(category, positionIndex);
  }

  Future<String> loadFen(PositionCategory category, int positionIndex) async {
    if (!isValidPositionIndex(positionIndex)) {
      throw RangeError.range(positionIndex, 1, 10000, 'positionIndex');
    }

    final lines = await _linesFor(category);
    if (positionIndex > lines.length) {
      throw RangeError.value(
        positionIndex,
        'positionIndex',
        'No FEN exists at this position index.',
      );
    }
    return lines[positionIndex - 1];
  }

  String difficultyForIndex(int index) {
    return PositionDifficulty.forIndex(index).label;
  }

  bool isValidPositionIndex(int index) {
    return index >= 1 && index <= 10000;
  }

  Future<List<String>> _linesFor(PositionCategory category) async {
    final cached = _moduleCache[category];
    if (cached != null) return cached;

    final text = await bundle.loadString(category.assetPath);
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    _moduleCache[category] = lines;
    return lines;
  }
}
