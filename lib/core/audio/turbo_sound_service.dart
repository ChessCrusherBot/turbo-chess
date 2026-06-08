import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TurboSoundEvent {
  move,
  capture,
  check,
  checkmate,
}

extension TurboSoundEventName on TurboSoundEvent {
  String get debugName => switch (this) {
        TurboSoundEvent.move => 'move',
        TurboSoundEvent.capture => 'capture',
        TurboSoundEvent.check => 'check',
        TurboSoundEvent.checkmate => 'checkmate',
      };
}

@immutable
class TurboSoundAsset {
  final String assetPath;
  final double volume;

  const TurboSoundAsset({
    required this.assetPath,
    required this.volume,
  });
}

abstract class TurboSoundBackend {
  Future<void> initialize(Map<TurboSoundEvent, TurboSoundAsset> assets);

  Future<void> play(TurboSoundEvent event);

  Future<void> dispose();
}

class TurboSoundService {
  TurboSoundService._({TurboSoundBackend? backend})
      : _backend = backend ?? AudioplayersTurboSoundBackend();

  static final TurboSoundService instance = TurboSoundService._();

  static const String soundEnabledKey = 'sound_enabled';
  static const String hapticEnabledKey = 'haptic_enabled';

  static const Map<TurboSoundEvent, TurboSoundAsset> soundAssets = {
    TurboSoundEvent.move: TurboSoundAsset(
      assetPath: 'sounds/chess/move.mp3',
      volume: 0.46,
    ),
    TurboSoundEvent.capture: TurboSoundAsset(
      assetPath: 'sounds/chess/capture.mp3',
      volume: 0.54,
    ),
    TurboSoundEvent.check: TurboSoundAsset(
      assetPath: 'sounds/chess/check.mp3',
      volume: 0.48,
    ),
    TurboSoundEvent.checkmate: TurboSoundAsset(
      assetPath: 'sounds/chess/checkmate.mp3',
      volume: 0.56,
    ),
  };

  TurboSoundBackend _backend;
  Future<void>? _initializeFuture;
  bool _backendReady = false;
  bool _enabled = true;
  bool _hapticEnabled = true;

  bool get isEnabled => _enabled;

  @visibleForTesting
  bool debugDisableAudioPlayback = false;

  @visibleForTesting
  bool debugDisableHaptics = false;

  @visibleForTesting
  String? debugLastSoundEvent;

  @visibleForTesting
  int debugSoundPlayCount = 0;

  @visibleForTesting
  List<TurboSoundEvent> debugSoundEvents = <TurboSoundEvent>[];

  Future<void> initialize() {
    _initializeFuture ??= _initialize();
    return _initializeFuture!;
  }

  Future<void> _initialize() async {
    await _loadPreferences();
    if (debugDisableAudioPlayback) {
      _backendReady = false;
      return;
    }

    try {
      await _backend.initialize(soundAssets);
      _backendReady = true;
    } catch (error, stackTrace) {
      _backendReady = false;
      _initializeFuture = null;
      _logAudioSkip('initialize', error, stackTrace);
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = _readBoolPreference(
        prefs,
        soundEnabledKey,
        defaultValue: true,
      );
      _hapticEnabled = _readBoolPreference(
        prefs,
        hapticEnabledKey,
        defaultValue: true,
      );
      if (debugDisableAudioPlayback || debugDisableHaptics) {
        _hapticEnabled = false;
      }
    } catch (error, stackTrace) {
      _enabled = true;
      _hapticEnabled = !(debugDisableAudioPlayback || debugDisableHaptics);
      _logAudioSkip('preference load', error, stackTrace);
    }
  }

  Future<void> reloadPreference() async {
    await _loadPreferences();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(soundEnabledKey, enabled);
    } catch (error, stackTrace) {
      _logAudioSkip('preference save', error, stackTrace);
    }
    if (enabled) {
      unawaited(initialize());
    }
  }

  Future<bool> isHapticEnabled() async {
    await _loadPreferences();
    return _hapticEnabled;
  }

  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(hapticEnabledKey, enabled);
    } catch (error, stackTrace) {
      _logAudioSkip('haptic preference save', error, stackTrace);
    }
  }

  void playMove() => playEvent(TurboSoundEvent.move);

  void playCapture() => playEvent(TurboSoundEvent.capture);

  void playCheck() => playEvent(TurboSoundEvent.check);

  void playCheckmate() => playEvent(TurboSoundEvent.checkmate);

  void playGameOver() => playCheckmate();

  void playCorrect() => playCheck();

  void playWrong() {
    if (_hapticEnabled && !debugDisableHaptics) {
      unawaited(HapticFeedback.heavyImpact());
    }
  }

  void playButtonTap() {
    if (_hapticEnabled && !debugDisableHaptics) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void playTap() => playButtonTap();

  void playEvent(TurboSoundEvent event) {
    switch (event) {
      case TurboSoundEvent.move:
        _play(event, HapticFeedback.selectionClick);
        return;
      case TurboSoundEvent.capture:
        _play(event, HapticFeedback.mediumImpact);
        return;
      case TurboSoundEvent.check:
        _play(event, HapticFeedback.mediumImpact);
        return;
      case TurboSoundEvent.checkmate:
        _play(event, HapticFeedback.heavyImpact);
        return;
    }
  }

  void _play(
    TurboSoundEvent event,
    Future<void> Function() haptic,
  ) {
    if (_hapticEnabled && !debugDisableHaptics) {
      unawaited(haptic());
    }
    if (!_enabled) return;

    debugLastSoundEvent = event.debugName;
    debugSoundPlayCount += 1;
    debugSoundEvents.add(event);
    if (debugDisableAudioPlayback) return;

    unawaited(_playSound(event));
  }

  Future<void> _playSound(TurboSoundEvent event) async {
    try {
      if (!_backendReady) {
        await initialize();
      }
      if (!_backendReady) return;
      await _backend.play(event);
    } catch (error, stackTrace) {
      _logAudioSkip(event.debugName, error, stackTrace);
    }
  }

  Future<void> dispose() async {
    try {
      await _backend.dispose();
    } catch (error, stackTrace) {
      _logAudioSkip('dispose', error, stackTrace);
    } finally {
      _backendReady = false;
      _initializeFuture = null;
    }
  }

  @visibleForTesting
  void debugResetForTesting({TurboSoundBackend? backend}) {
    unawaited(_backend.dispose());
    _backend = backend ?? _NoopTurboSoundBackend();
    _initializeFuture = null;
    _backendReady = false;
    _enabled = true;
    _hapticEnabled = false;
    debugDisableAudioPlayback = backend == null;
    debugDisableHaptics = true;
    debugLastSoundEvent = null;
    debugSoundPlayCount = 0;
    debugSoundEvents = <TurboSoundEvent>[];
  }

  static bool _readBoolPreference(
    SharedPreferences prefs,
    String key, {
    required bool defaultValue,
  }) {
    try {
      return prefs.getBool(key) ?? defaultValue;
    } catch (error, stackTrace) {
      unawaited(prefs.remove(key));
      _logAudioSkip('corrupt preference $key', error, stackTrace);
      return defaultValue;
    }
  }

  static void _logAudioSkip(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint('Turbo Chess sound skipped during $operation: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class AudioplayersTurboSoundBackend implements TurboSoundBackend {
  AudioplayersTurboSoundBackend({
    AudioCache? cache,
    TurboSoundEffectPlayerFactory? playerFactory,
    TurboSoundAssetPreloader? assetPreloader,
    TurboGlobalAudioContextSetter? globalAudioContextSetter,
  })  : _cache = cache ?? AudioCache(prefix: 'assets/'),
        _playerFactory = playerFactory ?? _createAudioplayersPlayer,
        _assetPreloader = assetPreloader,
        _globalAudioContextSetter =
            globalAudioContextSetter ?? AudioPlayer.global.setAudioContext;

  static const int _playersPerEvent = 2;
  static final AudioContext soundEffectAudioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  final AudioCache _cache;
  final TurboSoundEffectPlayerFactory _playerFactory;
  final TurboSoundAssetPreloader? _assetPreloader;
  final TurboGlobalAudioContextSetter _globalAudioContextSetter;
  final Map<TurboSoundEvent, List<TurboSoundEffectPlayer>> _players = {};
  final Map<TurboSoundEvent, int> _nextPlayerIndex = {};
  Map<TurboSoundEvent, TurboSoundAsset> _assets = const {};

  @override
  Future<void> initialize(Map<TurboSoundEvent, TurboSoundAsset> assets) async {
    _assets = Map<TurboSoundEvent, TurboSoundAsset>.unmodifiable(assets);
    await _configureGlobalAudioContext();
    await (_assetPreloader ?? _cache.loadAll).call(
      _assets.values.map((asset) => asset.assetPath).toList(growable: false),
    );

    for (final entry in _assets.entries) {
      final players = _players.putIfAbsent(
        entry.key,
        () => List<TurboSoundEffectPlayer>.generate(
          _playersPerEvent,
          (index) => _playerFactory(entry.key, index, _cache),
          growable: false,
        ),
      );
      _nextPlayerIndex[entry.key] = 0;
      for (final player in players) {
        await _configurePlayerAudioContext(player);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(entry.value.volume);
        await player.setSource(AssetSource(entry.value.assetPath));
      }
    }
  }

  @override
  Future<void> play(TurboSoundEvent event) async {
    final players = _players[event];
    final asset = _assets[event];
    if (players == null || players.isEmpty || asset == null) {
      throw StateError('Sound backend was not initialized for $event');
    }
    final index = _nextPlayerIndex[event] ?? 0;
    final player = players[index % players.length];
    _nextPlayerIndex[event] = (index + 1) % players.length;
    await player.stop();
    await player.setVolume(asset.volume);
    await player.setSource(AssetSource(asset.assetPath));
    await player.resume();
  }

  Future<void> _configureGlobalAudioContext() async {
    try {
      await _globalAudioContextSetter(soundEffectAudioContext);
    } catch (error, stackTrace) {
      TurboSoundService._logAudioSkip(
        'global audio context',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _configurePlayerAudioContext(
    TurboSoundEffectPlayer player,
  ) async {
    try {
      await player.setAudioContext(soundEffectAudioContext);
    } catch (error, stackTrace) {
      TurboSoundService._logAudioSkip(
        'player audio context',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> dispose() async {
    final players = _players.values.expand((list) => list).toList(
          growable: false,
        );
    _players.clear();
    _nextPlayerIndex.clear();
    _assets = const {};
    await Future.wait(players.map((player) => player.dispose()));
    await _cache.clearAll();
  }
}

typedef TurboSoundEffectPlayerFactory = TurboSoundEffectPlayer Function(
  TurboSoundEvent event,
  int index,
  AudioCache cache,
);

typedef TurboSoundAssetPreloader = Future<List<Uri>> Function(
  Iterable<String> paths,
);

typedef TurboGlobalAudioContextSetter = Future<void> Function(
  AudioContext context,
);

TurboSoundEffectPlayer _createAudioplayersPlayer(
  TurboSoundEvent event,
  int index,
  AudioCache cache,
) {
  return AudioplayersSoundEffectPlayer(
    playerId: 'turbo_${event.debugName}_sfx_$index',
    cache: cache,
  );
}

@visibleForTesting
abstract class TurboSoundEffectPlayer {
  Future<void> setAudioContext(AudioContext context);

  Future<void> setPlayerMode(PlayerMode mode);

  Future<void> setReleaseMode(ReleaseMode releaseMode);

  Future<void> setVolume(double volume);

  Future<void> setSource(Source source);

  Future<void> stop();

  Future<void> resume();

  Future<void> dispose();
}

class AudioplayersSoundEffectPlayer implements TurboSoundEffectPlayer {
  AudioplayersSoundEffectPlayer({
    required String playerId,
    required AudioCache cache,
  }) : _player = AudioPlayer(playerId: playerId) {
    _player.audioCache = cache;
  }

  final AudioPlayer _player;

  @override
  Future<void> setAudioContext(AudioContext context) {
    return _player.setAudioContext(context);
  }

  @override
  Future<void> setPlayerMode(PlayerMode mode) {
    return _player.setPlayerMode(mode);
  }

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) {
    return _player.setReleaseMode(releaseMode);
  }

  @override
  Future<void> setVolume(double volume) {
    return _player.setVolume(volume);
  }

  @override
  Future<void> setSource(Source source) {
    return _player.setSource(source);
  }

  @override
  Future<void> stop() {
    return _player.stop();
  }

  @override
  Future<void> resume() {
    return _player.resume();
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }
}

class _NoopTurboSoundBackend implements TurboSoundBackend {
  @override
  Future<void> initialize(Map<TurboSoundEvent, TurboSoundAsset> assets) async {}

  @override
  Future<void> play(TurboSoundEvent event) async {}

  @override
  Future<void> dispose() async {}
}
