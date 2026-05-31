// UCI Protocol Parser

import 'engine_evaluation.dart';

class UCIParser {
  /// Parse UCI info line
  static UCIInfo? parseInfoLine(String line) {
    if (!line.startsWith('info')) return null;

    final tokens = line.split(' ');
    final info = UCIInfo();

    for (var i = 0; i < tokens.length; i++) {
      switch (tokens[i]) {
        case 'depth':
          info.depth = _parseInt(tokens, i);
          break;
        case 'seldepth':
          info.selDepth = _parseInt(tokens, i);
          break;
        case 'multipv':
          info.multiPV = _parseInt(tokens, i);
          break;
        case 'score':
          _parseScore(tokens, i, info);
          break;
        case 'nodes':
          info.nodes = _parseInt(tokens, i);
          break;
        case 'nps':
          info.nps = _parseInt(tokens, i);
          break;
        case 'hashfull':
          info.hashFull = _parseInt(tokens, i);
          break;
        case 'tbhits':
          info.tbHits = _parseInt(tokens, i);
          break;
        case 'time':
          info.time = _parseInt(tokens, i);
          break;
        case 'pv':
          info.pv = _parsePV(tokens, i);
          break;
        case 'currmove':
          if (i + 1 < tokens.length) info.currentMove = tokens[i + 1];
          break;
        case 'currmovenumber':
          info.currentMoveNumber = _parseInt(tokens, i);
          break;
      }
    }

    return info;
  }

  /// Parse bestmove line
  static UCIBestMove? parseBestMove(String line) {
    if (!line.startsWith('bestmove')) return null;

    final tokens = line.split(' ');
    if (tokens.length < 2) return null;

    return UCIBestMove(
      bestMove: tokens[1],
      ponder: tokens.length >= 4 && tokens[2] == 'ponder' ? tokens[3] : null,
    );
  }

  /// Parse UCI option
  static UCIOption? parseOption(String line) {
    if (!line.startsWith('option')) return null;

    final tokens = line.split(' ');
    final option = UCIOption();

    for (var i = 0; i < tokens.length; i++) {
      switch (tokens[i]) {
        case 'name':
          if (i + 1 < tokens.length) option.name = tokens[i + 1];
          break;
        case 'type':
          if (i + 1 < tokens.length) option.type = tokens[i + 1];
          break;
        case 'default':
          if (i + 1 < tokens.length) option.defaultValue = tokens[i + 1];
          break;
        case 'min':
          option.min = _parseInt(tokens, i);
          break;
        case 'max':
          option.max = _parseInt(tokens, i);
          break;
      }
    }

    return option;
  }

  // ==================== PRIVATE ====================

  static int? _parseInt(List<String> tokens, int index) {
    if (index + 1 < tokens.length) {
      return int.tryParse(tokens[index + 1]);
    }
    return null;
  }

  static void _parseScore(List<String> tokens, int index, UCIInfo info) {
    if (index + 2 >= tokens.length) return;

    final type = tokens[index + 1];
    final value = tokens[index + 2];

    if (type == 'cp') {
      info.scoreType = ScoreType.centipawns;
      info.score = int.tryParse(value) ?? 0;
    } else if (type == 'mate') {
      info.scoreType = ScoreType.mate;
      info.mateIn = int.tryParse(value);
      info.score =
          info.mateIn != null ? EngineEvaluation.encodeMate(info.mateIn!) : 0;
    } else if (type == 'lowerbound') {
      info.isLowerBound = true;
    } else if (type == 'upperbound') {
      info.isUpperBound = true;
    }
  }

  static List<String> _parsePV(List<String> tokens, int index) {
    if (index + 1 >= tokens.length) return [];
    return tokens.sublist(index + 1);
  }
}

/// UCI Info data class
class UCIInfo {
  int? depth;
  int? selDepth;
  int? multiPV;
  int score = 0;
  ScoreType scoreType = ScoreType.centipawns;
  int? mateIn;
  bool isLowerBound = false;
  bool isUpperBound = false;
  int? nodes;
  int? nps;
  int? hashFull;
  int? tbHits;
  int? time;
  List<String> pv = [];
  String? currentMove;
  int? currentMoveNumber;

  /// Get score as readable string
  String get scoreString {
    if (scoreType == ScoreType.mate) {
      return mateIn != null
          ? '${mateIn! > 0 ? '+' : '-'}M${mateIn!.abs()}'
          : 'M?';
    }
    return EngineEvaluation.formatWhiteScore(score);
  }

  /// Check if position is winning
  bool get isWinning => scoreType == ScoreType.centipawns && score > 100;

  /// Check if position is losing
  bool get isLosing => scoreType == ScoreType.centipawns && score < -100;
}

/// UCI Best Move data class
class UCIBestMove {
  final String bestMove;
  final String? ponder;

  const UCIBestMove({required this.bestMove, this.ponder});
}

/// UCI Option data class
class UCIOption {
  String? name;
  String? type;
  String? defaultValue;
  int? min;
  int? max;
}

/// Score type enum
enum ScoreType { centipawns, mate }
