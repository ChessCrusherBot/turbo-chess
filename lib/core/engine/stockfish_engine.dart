import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../chess/chess_board.dart';
import 'chess_rules.dart';
import 'engine_evaluation.dart';
import 'engine_power_profile.dart';
import 'engine_health_report.dart';

enum EngineState { idle, initializing, thinking, stopped, error }

class StockfishEngine {
  static const MethodChannel _platformChannel =
      MethodChannel('com.turbochess.app/stockfish');
  static const String _healthCheckFen =
      'r1bqkbnr/pppp1ppp/2n5/4p3/3PP3/5N2/PPPQ1PPP/RNB1KB1R w KQkq - 2 4';

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  EngineState _state = EngineState.idle;
  String? _enginePath;
  String? _engineId;
  _EngineBinaryInfo? _binaryInfo;
  Completer<String?>? _bestMoveCompleter;
  Completer<int?>? _evaluationCompleter;
  Completer<void>? _uciCompleter;
  Completer<void>? _readyCompleter;
  Future<bool>? _initializeFuture;
  Future<void> _commandQueue = Future<void>.value();
  int _lastScore = 0;
  int _lastDepth = 0;
  bool _lastUciHandshakeOk = false;
  final Map<String, _UciEngineOption> _uciOptions = {};
  EngineDeviceProfile? _deviceProfile;

  EngineState get state => _state;
  bool get isReady => _state == EngineState.idle && _process != null;
  String? get enginePath => _enginePath;
  String? get engineId => _engineId;
  List<String> get supportedAbis => _binaryInfo?.supportedAbis ?? const [];
  Set<String> get supportedUciOptions =>
      _uciOptions.values.map((option) => option.name).toSet();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<bool> initialize({bool force = false}) {
    if (!force && _process != null && _state == EngineState.idle) {
      return Future<bool>.value(true);
    }
    if (!force && _initializeFuture != null) {
      return _initializeFuture!;
    }

    final future = _initializeInternal(force: force);
    _initializeFuture = future;
    return future.whenComplete(() {
      if (identical(_initializeFuture, future)) {
        _initializeFuture = null;
      }
    });
  }

  Future<bool> restart() async {
    return initialize(force: true);
  }

  Future<String?> getBestMove(String fen, int timeMs) {
    return _enqueue(() => _getBestMoveInternal(fen, 'go movetime $timeMs'));
  }

  Future<String?> getBestMoveByDepth(String fen, int depth) {
    return _enqueue(() => _getBestMoveByDepthInternal(fen, depth));
  }

  Future<String?> getBestMoveWithProfile(
    String fen,
    EnginePowerProfile profile,
  ) {
    return _enqueue(() async {
      final config = await _resolveSearchConfig(profile);
      return _getBestMoveInternal(
        fen,
        config.goCommand,
        timeout: config.timeout,
        config: config,
      );
    });
  }

  Future<String?> getBestMoveWithConfig(
    String fen,
    EngineSearchConfig config,
  ) {
    return _enqueue(
      () => _getBestMoveInternal(
        fen,
        config.goCommand,
        timeout: config.timeout,
        config: config,
      ),
    );
  }

  Future<int?> getEvaluationScore(String fen, int depth) {
    return _enqueue(() => _getEvaluationScoreInternal(fen, depth));
  }

  Future<EngineHealthReport> runHealthCheck({bool forceRestart = false}) {
    return _enqueue(() async {
      _binaryInfo = await _resolveEngineBinary();
      final binaryInfo = _binaryInfo ??
          const _EngineBinaryInfo(
            exists: false,
            supportedAbis: <String>[],
            error: 'Unable to inspect the packaged Stockfish binary.',
          );

      if (forceRestart) {
        await _shutdownInternal(finalState: EngineState.stopped);
      }

      final initialized = await initialize(force: forceRestart);
      final readyOk = initialized
          ? await _pingReady(timeout: const Duration(seconds: 4))
          : false;
      final processStarted = _process != null;
      final bestMove = readyOk
          ? await _getBestMoveByDepthInternal(_healthCheckFen, 4)
          : null;
      final bestMoveOk = _isLegalHealthMove(bestMove);
      final evaluation = readyOk
          ? await _getEvaluationScoreInternal(_healthCheckFen, 4)
          : null;
      final evaluationOk = evaluation != null;

      String? error = binaryInfo.error;
      if (!binaryInfo.exists) {
        error ??= 'Bundled Stockfish binary is missing for the current ABI.';
      } else if (!initialized) {
        error ??= 'Stockfish failed to initialize.';
      } else if (!readyOk) {
        error ??= 'Stockfish did not respond to isready.';
      } else if (!bestMoveOk) {
        error ??=
            'Stockfish did not return a legal bestmove for the health-check FEN.';
      } else if (!evaluationOk) {
        error ??=
            'Stockfish did not return an evaluation for the health-check FEN.';
      }

      final report = EngineHealthReport(
        checkedAt: DateTime.now(),
        usingFallback:
            !binaryInfo.exists || !readyOk || !bestMoveOk || !evaluationOk,
        binaryExists: binaryInfo.exists,
        processStarted: processStarted,
        uciHandshakeOk: _lastUciHandshakeOk,
        readyOk: readyOk,
        bestMoveOk: bestMoveOk,
        evaluationOk: evaluationOk,
        bestMove: bestMove,
        evaluation: evaluation,
        enginePath: binaryInfo.enginePath,
        engineId: _engineId,
        supportedAbis: binaryInfo.supportedAbis,
        error: error,
      );

      await _shutdownInternal(finalState: EngineState.stopped);
      return report;
    });
  }

  Future<void> shutdown() {
    return _enqueue(() => _shutdownInternal(finalState: EngineState.stopped));
  }

  Future<bool> _initializeInternal({required bool force}) async {
    if (force) {
      await _shutdownInternal(finalState: EngineState.stopped);
    } else if (_process != null && _state == EngineState.idle) {
      return true;
    }

    _state = EngineState.initializing;
    _engineId = null;
    _lastUciHandshakeOk = false;
    _uciOptions.clear();
    _binaryInfo = await _resolveEngineBinary();
    _deviceProfile ??= await _resolveDeviceProfile();
    _enginePath = _binaryInfo?.enginePath;
    _log('Stockfish initialize requested for path=$_enginePath');

    if (_binaryInfo == null || !_binaryInfo!.exists || _enginePath == null) {
      _state = EngineState.error;
      return false;
    }

    try {
      _process = await Process.start(_enginePath!, const [], runInShell: false);
      _log('Stockfish process started from $_enginePath');

      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleEngineLine);
      _stderrSub = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _log('Stockfish stderr: $line'));
      unawaited(
        _process!.exitCode.then((code) {
          if (_state == EngineState.stopped) return;
          _log('Stockfish exited unexpectedly with code $code');
          _state = EngineState.error;
          _process = null;
        }),
      );

      final uciCompleter = Completer<void>();
      _uciCompleter = uciCompleter;
      _sendCommand('uci');
      await uciCompleter.future.timeout(const Duration(seconds: 10));
      _lastUciHandshakeOk = true;

      await _applySearchConfig(
        EnginePowerProfile.strong.resolve(device: _deviceProfile),
      );

      if (!await _pingReady(timeout: const Duration(seconds: 10))) {
        throw TimeoutException('Stockfish isready timed out');
      }

      _state = EngineState.idle;
      return true;
    } catch (e) {
      _log('Stockfish initialize failed: $e');
      await _shutdownInternal(finalState: EngineState.error);
      return false;
    }
  }

  Future<String?> _getBestMoveByDepthInternal(String fen, int depth) {
    return _getBestMoveInternal(fen, 'go depth $depth');
  }

  Future<String?> _getBestMoveInternal(
    String fen,
    String goCommand, {
    Duration timeout = const Duration(seconds: 10),
    EngineSearchConfig? config,
  }) async {
    Completer<String?>? completer;
    try {
      if (!await initialize()) return null;
      if (config != null) {
        await _applySearchConfig(config);
      }
      await _stopThinkingIfNeeded();
      _resetSearchState();
      completer = Completer<String?>();
      _bestMoveCompleter = completer;
      _state = EngineState.thinking;
      _sendCommand('position fen $fen');
      _sendCommand(goCommand);
      final bestMove = await completer.future.timeout(timeout);
      return _normalizeMove(bestMove);
    } on TimeoutException {
      _log('Stockfish best move timed out.');
      _sendCommand('stop');
      String? stoppedMove;
      if (completer != null) {
        stoppedMove = await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      }
      await _pingReady(timeout: const Duration(seconds: 2));
      return _normalizeMove(stoppedMove);
    } catch (e) {
      _log('Stockfish best move error: $e');
      _state = EngineState.error;
      return null;
    } finally {
      if (_state == EngineState.thinking) {
        _state = EngineState.idle;
      }
      if (identical(_bestMoveCompleter, completer)) {
        _bestMoveCompleter = null;
      }
    }
  }

  Future<int?> _getEvaluationScoreInternal(String fen, int depth) async {
    Completer<int?>? completer;
    try {
      if (!await initialize()) return null;
      await _stopThinkingIfNeeded();
      _resetSearchState();
      completer = Completer<int?>();
      _evaluationCompleter = completer;
      _state = EngineState.thinking;
      _sendCommand('position fen $fen');
      _sendCommand('go depth $depth');
      return await completer.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _log('Stockfish evaluation timed out.');
      _sendCommand('stop');
      int? stoppedScore;
      if (completer != null) {
        stoppedScore = await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      }
      await _pingReady(timeout: const Duration(seconds: 2));
      return stoppedScore;
    } catch (e) {
      _log('Stockfish evaluation error: $e');
      _state = EngineState.error;
      return null;
    } finally {
      if (_state == EngineState.thinking) {
        _state = EngineState.idle;
      }
      if (identical(_evaluationCompleter, completer)) {
        _evaluationCompleter = null;
      }
    }
  }

  Future<EngineSearchConfig> _resolveSearchConfig(
    EnginePowerProfile profile,
  ) async {
    _deviceProfile ??= await _resolveDeviceProfile();
    return profile.resolve(device: _deviceProfile);
  }

  Future<EngineDeviceProfile> _resolveDeviceProfile() async {
    if (!Platform.isAndroid) {
      return EngineDeviceProfile(
        isLowRamDevice: false,
        processorCount: Platform.numberOfProcessors,
      );
    }

    try {
      final payload = await _platformChannel
          .invokeMapMethod<String, dynamic>('getDeviceProfile');
      return EngineDeviceProfile(
        isLowRamDevice: payload?['lowRamDevice'] == true,
        processorCount: Platform.numberOfProcessors,
        memoryClassMb: payload?['memoryClassMb'] as int?,
        largeMemoryClassMb: payload?['largeMemoryClassMb'] as int?,
        totalMemoryMb: payload?['totalMemoryMb'] as int?,
        availableMemoryMb: payload?['availableMemoryMb'] as int?,
      );
    } catch (e) {
      _log('Device profile lookup failed: $e');
      return EngineDeviceProfile(
        isLowRamDevice: false,
        processorCount: Platform.numberOfProcessors,
      );
    }
  }

  Future<void> _applySearchConfig(EngineSearchConfig config) async {
    _setOptionBool('UCI_LimitStrength', config.limitStrength);
    _setOptionInt('Skill Level', config.skillLevel);
    _setOptionBool('Ponder', config.ponder);
    _setOptionInt('Threads', config.threads);
    _setOptionInt('Hash', config.hashMb);
    _setOptionBool('Use NNUE', true);
    await _pingReady(timeout: const Duration(seconds: 5));
  }

  void _setOptionBool(String name, bool value) {
    _setOptionValue(name, value ? 'true' : 'false');
  }

  void _setOptionInt(String name, int value) {
    final option = _optionNamed(name);
    if (option == null) return;

    var boundedValue = value;
    if (option.min != null && boundedValue < option.min!) {
      boundedValue = option.min!;
    }
    if (option.max != null && boundedValue > option.max!) {
      boundedValue = option.max!;
    }

    _sendCommand('setoption name ${option.name} value $boundedValue');
  }

  void _setOptionValue(String name, String value) {
    final option = _optionNamed(name);
    if (option == null) return;
    _sendCommand('setoption name ${option.name} value $value');
  }

  _UciEngineOption? _optionNamed(String name) {
    return _uciOptions[_normalizeOptionName(name)];
  }

  String _normalizeOptionName(String name) => name.trim().toLowerCase();

  Future<_EngineBinaryInfo?> _resolveEngineBinary() async {
    if (!Platform.isAndroid) {
      return const _EngineBinaryInfo(
        exists: false,
        supportedAbis: <String>[],
        error: 'Stockfish native packaging is only supported on Android.',
      );
    }

    try {
      final payload = await _platformChannel
          .invokeMapMethod<String, dynamic>('getEngineInfo');
      final supportedAbis = List<String>.from(
        payload?['supportedAbis'] as List? ?? const <String>[],
      );
      final enginePath = payload?['stockfishPath'] as String?;
      final exists = enginePath != null && await File(enginePath).exists();
      return _EngineBinaryInfo(
        enginePath: enginePath,
        exists: exists,
        supportedAbis: supportedAbis,
        error: exists
            ? null
            : 'libstockfish.so was not found in nativeLibraryDir.',
      );
    } catch (e) {
      _log('Stockfish binary lookup failed: $e');
      return _EngineBinaryInfo(
        exists: false,
        supportedAbis: const <String>[],
        error: 'Failed to inspect Android nativeLibraryDir: $e',
      );
    }
  }

  void _sendCommand(String command) {
    _process?.stdin.writeln(command);
  }

  void _resetSearchState() {
    _lastScore = 0;
    _lastDepth = 0;
  }

  void _handleEngineLine(String line) {
    if (line.startsWith('id name ')) {
      _engineId = line.substring('id name '.length).trim();
      return;
    }
    if (line == 'uciok' &&
        _uciCompleter != null &&
        !_uciCompleter!.isCompleted) {
      _uciCompleter!.complete();
      return;
    }
    if (line == 'readyok' &&
        _readyCompleter != null &&
        !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete();
      return;
    }
    if (line.startsWith('option name ')) {
      final option = _UciEngineOption.tryParse(line);
      if (option != null) {
        _uciOptions[_normalizeOptionName(option.name)] = option;
      }
      return;
    }

    if (line.startsWith('info') && line.contains('score')) {
      final parts = line.split(' ');
      final depthIndex = parts.indexOf('depth');
      final scoreIndex = parts.indexOf('score');
      final depth = depthIndex >= 0 && depthIndex + 1 < parts.length
          ? int.tryParse(parts[depthIndex + 1]) ?? 0
          : 0;
      if (scoreIndex >= 0 && scoreIndex + 2 < parts.length) {
        final scoreType = parts[scoreIndex + 1];
        final scoreValue = parts[scoreIndex + 2];
        var parsedScore = 0;
        if (scoreType == 'cp') {
          parsedScore = int.tryParse(scoreValue) ?? 0;
        } else if (scoreType == 'mate') {
          final mateMoves = int.tryParse(scoreValue) ?? 0;
          parsedScore = EngineEvaluation.encodeMate(mateMoves);
        }
        if (depth >= _lastDepth) {
          _lastDepth = depth;
          _lastScore = parsedScore;
        }
      }
      return;
    }

    if (!line.startsWith('bestmove')) return;
    final parts = line.split(' ');
    final bestMove = parts.length >= 2 ? parts[1] : null;

    if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
      _bestMoveCompleter!.complete(bestMove);
    }
    if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted) {
      _evaluationCompleter!.complete(_lastScore);
    }
    _bestMoveCompleter = null;
    _evaluationCompleter = null;
    _state = EngineState.idle;
  }

  Future<void> _stopThinkingIfNeeded() async {
    if (_state != EngineState.thinking) return;
    _sendCommand('stop');
    await _pingReady(timeout: const Duration(seconds: 2));
  }

  Future<bool> _pingReady(
      {Duration timeout = const Duration(seconds: 5)}) async {
    if (_process == null) {
      return false;
    }

    final completer = Completer<void>();
    _readyCompleter = completer;
    _sendCommand('isready');
    try {
      await completer.future.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    } finally {
      if (identical(_readyCompleter, completer)) {
        _readyCompleter = null;
      }
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _commandQueue = _commandQueue.catchError((_) {}).then<void>((_) async {
      try {
        completer.complete(await action());
      } catch (e, stackTrace) {
        completer.completeError(e, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _shutdownInternal({required EngineState finalState}) async {
    try {
      _sendCommand('quit');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    } catch (_) {}
    try {
      _process?.kill();
    } catch (_) {}

    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _process = null;

    if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
      _bestMoveCompleter!.complete(null);
    }
    if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted) {
      _evaluationCompleter!.complete(null);
    }
    if (_uciCompleter != null && !_uciCompleter!.isCompleted) {
      _uciCompleter!.completeError(const ProcessException(
        'stockfish',
        <String>[],
        'Engine shut down',
      ));
    }
    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.completeError(const ProcessException(
        'stockfish',
        <String>[],
        'Engine shut down',
      ));
    }

    _bestMoveCompleter = null;
    _evaluationCompleter = null;
    _uciCompleter = null;
    _readyCompleter = null;
    _state = finalState;
  }

  bool _isLegalHealthMove(String? move) {
    final normalized = _normalizeMove(move);
    if (normalized == null) return false;
    final legalMoves =
        ChessRules.getLegalMoveUcis(ChessBoard.fromFen(_healthCheckFen));
    return legalMoves.contains(normalized);
  }

  String? _normalizeMove(String? move) {
    if (move == null) return null;
    final normalized = move.trim().toLowerCase();
    if (normalized.length < 4 || normalized == '0000') {
      return null;
    }
    return normalized.length > 5 ? normalized.substring(0, 5) : normalized;
  }
}

class _EngineBinaryInfo {
  final String? enginePath;
  final bool exists;
  final List<String> supportedAbis;
  final String? error;

  const _EngineBinaryInfo({
    this.enginePath,
    required this.exists,
    required this.supportedAbis,
    this.error,
  });
}

class _UciEngineOption {
  final String name;
  final int? min;
  final int? max;

  const _UciEngineOption({
    required this.name,
    this.min,
    this.max,
  });

  static _UciEngineOption? tryParse(String line) {
    const namePrefix = 'option name ';
    if (!line.startsWith(namePrefix)) return null;

    final typeIndex = line.indexOf(' type ', namePrefix.length);
    if (typeIndex <= namePrefix.length) return null;

    final name = line.substring(namePrefix.length, typeIndex).trim();
    if (name.isEmpty) return null;

    final tokens = line.substring(typeIndex + 1).split(' ');
    return _UciEngineOption(
      name: name,
      min: _intAfter(tokens, 'min'),
      max: _intAfter(tokens, 'max'),
    );
  }

  static int? _intAfter(List<String> tokens, String marker) {
    final index = tokens.indexOf(marker);
    if (index < 0 || index + 1 >= tokens.length) return null;
    return int.tryParse(tokens[index + 1]);
  }
}
