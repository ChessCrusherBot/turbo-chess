class EngineHealthReport {
  final DateTime checkedAt;
  final bool usingFallback;
  final bool binaryExists;
  final bool processStarted;
  final bool uciHandshakeOk;
  final bool readyOk;
  final bool bestMoveOk;
  final bool evaluationOk;
  final String? bestMove;
  final int? evaluation;
  final String? enginePath;
  final String? engineId;
  final List<String> supportedAbis;
  final String? error;

  const EngineHealthReport({
    required this.checkedAt,
    required this.usingFallback,
    required this.binaryExists,
    required this.processStarted,
    required this.uciHandshakeOk,
    required this.readyOk,
    required this.bestMoveOk,
    required this.evaluationOk,
    this.bestMove,
    this.evaluation,
    this.enginePath,
    this.engineId,
    this.supportedAbis = const [],
    this.error,
  });

  bool get isHealthy =>
      !usingFallback &&
      binaryExists &&
      processStarted &&
      uciHandshakeOk &&
      readyOk &&
      bestMoveOk &&
      evaluationOk;
}
