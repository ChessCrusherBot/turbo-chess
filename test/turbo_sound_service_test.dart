import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TurboSoundService service;
  late _FakeTurboSoundBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = TurboSoundService.instance;
    backend = _FakeTurboSoundBackend();
    service.debugResetForTesting(backend: backend);
  });

  test('service initializes and preloads configured sound assets', () async {
    await service.initialize();

    expect(service.isEnabled, isTrue);
    expect(backend.initializeCount, 1);
    expect(backend.assets.keys, containsAll(TurboSoundEvent.values));
    expect(
      backend.assets[TurboSoundEvent.move]?.assetPath,
      'sounds/chess/move.mp3',
    );
  });

  test('sound disabled prevents playback', () async {
    await service.initialize();
    await service.setEnabled(false);

    service.playMove();
    await _flushSoundTasks();

    expect(backend.playedEvents, isEmpty);
    expect(service.debugSoundPlayCount, 0);
  });

  test('sound enabled allows playback call', () async {
    await service.initialize();

    service.playMove();
    await _flushSoundTasks();

    expect(backend.playedEvents, [TurboSoundEvent.move]);
    expect(service.debugLastSoundEvent, 'move');
    expect(service.debugSoundPlayCount, 1);
  });

  test('missing audio file does not crash initialization or playback',
      () async {
    backend.throwOnInitialize = true;

    await expectLater(service.initialize(), completes);
    service.playMove();
    await _flushSoundTasks();

    expect(service.debugLastSoundEvent, 'move');
    expect(backend.playedEvents, isEmpty);
  });

  test('playback failure does not crash app flow', () async {
    backend.throwOnPlay = true;
    await service.initialize();

    service.playCapture();
    await _flushSoundTasks();

    expect(service.debugLastSoundEvent, 'capture');
    expect(service.debugSoundPlayCount, 1);
    expect(backend.playAttempts, 1);
  });

  test('sound preference persists', () async {
    await service.initialize();
    await service.setEnabled(false);

    final secondBackend = _FakeTurboSoundBackend();
    service.debugResetForTesting(backend: secondBackend);
    await service.initialize();

    expect(service.isEnabled, isFalse);
    service.playMove();
    await _flushSoundTasks();
    expect(secondBackend.playedEvents, isEmpty);
  });

  test('corrupt sound preference defaults safely to enabled', () async {
    SharedPreferences.setMockInitialValues({
      TurboSoundService.soundEnabledKey: 'not-a-bool',
    });
    service.debugResetForTesting(backend: backend);

    await expectLater(service.initialize(), completes);

    expect(service.isEnabled, isTrue);
  });

  test('sound effect audio context mixes without Android focus gain', () {
    final context = AudioplayersTurboSoundBackend.soundEffectAudioContext;

    expect(context.android.audioFocus, AndroidAudioFocus.none);
    expect(context.android.usageType, AndroidUsageType.game);
    expect(context.android.contentType, AndroidContentType.sonification);
    expect(context.android.stayAwake, isFalse);
    expect(context.iOS.category, AVAudioSessionCategory.playback);
    expect(
      context.iOS.options,
      contains(AVAudioSessionOptions.mixWithOthers),
    );
    expect(
      context.iOS.options,
      isNot(contains(AVAudioSessionOptions.duckOthers)),
    );
  });

  test('audioplayers backend applies mixing context to every pooled player',
      () async {
    final fakePlayers = <_FakeSoundEffectPlayer>[];
    final globalContexts = <AudioContext>[];
    final backend = AudioplayersTurboSoundBackend(
      playerFactory: (event, index, cache) {
        final player = _FakeSoundEffectPlayer(event: event, index: index);
        fakePlayers.add(player);
        return player;
      },
      assetPreloader: (paths) async => const <Uri>[],
      globalAudioContextSetter: (context) async {
        globalContexts.add(context);
      },
    );

    await backend.initialize(TurboSoundService.soundAssets);

    expect(globalContexts, [
      AudioplayersTurboSoundBackend.soundEffectAudioContext,
    ]);
    expect(fakePlayers, hasLength(TurboSoundEvent.values.length * 3));
    for (final player in fakePlayers) {
      expect(player.audioContexts, [
        AudioplayersTurboSoundBackend.soundEffectAudioContext,
      ]);
      expect(player.playerModes, [PlayerMode.lowLatency]);
      expect(player.releaseModes, [ReleaseMode.stop]);
      expect(player.sources.single, isA<AssetSource>());
    }

    await backend.dispose();
  });

  test('sound asset files and legal docs exist', () {
    for (final fileName in const [
      'move.mp3',
      'capture.mp3',
      'check.mp3',
      'checkmate.mp3',
      'README.md',
      'SOURCE.md',
      'LICENSES.md',
      'VERIFICATION.md',
    ]) {
      final file = File('assets/sounds/chess/$fileName');
      expect(file.existsSync(), isTrue, reason: fileName);
      expect(file.lengthSync(), greaterThan(0), reason: fileName);
    }
  });

  test('pubspec registers clean chess sound folder', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/sounds/chess/'));
  });

  test('old root sound files and docs are not left behind', () {
    for (final path in const [
      'assets/sounds/move.wav',
      'assets/sounds/capture.wav',
      'assets/sounds/check.wav',
      'assets/sounds/checkmate.wav',
      'assets/sounds/README.txt',
      'assets/sounds/NOTICE.txt',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });
}

Future<void> _flushSoundTasks() {
  return Future<void>.delayed(const Duration(milliseconds: 20));
}

class _FakeTurboSoundBackend implements TurboSoundBackend {
  int initializeCount = 0;
  int playAttempts = 0;
  bool throwOnInitialize = false;
  bool throwOnPlay = false;
  Map<TurboSoundEvent, TurboSoundAsset> assets = const {};
  final List<TurboSoundEvent> playedEvents = <TurboSoundEvent>[];

  @override
  Future<void> initialize(Map<TurboSoundEvent, TurboSoundAsset> assets) async {
    initializeCount += 1;
    this.assets = Map<TurboSoundEvent, TurboSoundAsset>.unmodifiable(assets);
    if (throwOnInitialize) {
      throw StateError('missing test asset');
    }
  }

  @override
  Future<void> play(TurboSoundEvent event) async {
    playAttempts += 1;
    if (throwOnPlay) {
      throw StateError('playback failed');
    }
    playedEvents.add(event);
  }

  @override
  Future<void> dispose() async {}
}

class _FakeSoundEffectPlayer implements TurboSoundEffectPlayer {
  final TurboSoundEvent event;
  final int index;
  final List<AudioContext> audioContexts = <AudioContext>[];
  final List<PlayerMode> playerModes = <PlayerMode>[];
  final List<ReleaseMode> releaseModes = <ReleaseMode>[];
  final List<double> volumes = <double>[];
  final List<Source> sources = <Source>[];
  int stopCount = 0;
  int resumeCount = 0;
  bool disposed = false;

  _FakeSoundEffectPlayer({
    required this.event,
    required this.index,
  });

  @override
  Future<void> setAudioContext(AudioContext context) async {
    audioContexts.add(context);
  }

  @override
  Future<void> setPlayerMode(PlayerMode mode) async {
    playerModes.add(mode);
  }

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {
    releaseModes.add(releaseMode);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> setSource(Source source) async {
    sources.add(source);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  @override
  Future<void> resume() async {
    resumeCount += 1;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
