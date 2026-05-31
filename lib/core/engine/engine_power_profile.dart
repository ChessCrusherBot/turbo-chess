class EngineDeviceProfile {
  final bool isLowRamDevice;
  final int? memoryClassMb;
  final int? largeMemoryClassMb;
  final int? totalMemoryMb;
  final int? availableMemoryMb;
  final int processorCount;

  const EngineDeviceProfile({
    required this.isLowRamDevice,
    required this.processorCount,
    this.memoryClassMb,
    this.largeMemoryClassMb,
    this.totalMemoryMb,
    this.availableMemoryMb,
  });

  const EngineDeviceProfile.unknown()
      : isLowRamDevice = false,
        processorCount = 1,
        memoryClassMb = null,
        largeMemoryClassMb = null,
        totalMemoryMb = null,
        availableMemoryMb = null;

  bool get hasModernHeadroom {
    final memoryClass = memoryClassMb ?? largeMemoryClassMb ?? 0;
    final totalMemory = totalMemoryMb ?? 0;
    return !isLowRamDevice &&
        processorCount >= 8 &&
        (memoryClass >= 384 || totalMemory >= 6000);
  }

  bool get hasModerateHeadroom {
    final memoryClass = memoryClassMb ?? largeMemoryClassMb ?? 0;
    final totalMemory = totalMemoryMb ?? 0;
    return !isLowRamDevice &&
        processorCount >= 4 &&
        (memoryClass >= 256 || totalMemory >= 3500);
  }
}

enum EnginePowerProfile {
  strong,
  master,
  max;

  static const String preferencesKey = 'engine_power_profile';

  static EnginePowerProfile fromId(String? id) {
    for (final profile in values) {
      if (profile.id == id) return profile;
    }
    return EnginePowerProfile.strong;
  }

  String get id {
    switch (this) {
      case EnginePowerProfile.strong:
        return 'strong';
      case EnginePowerProfile.master:
        return 'master';
      case EnginePowerProfile.max:
        return 'max';
    }
  }

  String get label {
    switch (this) {
      case EnginePowerProfile.strong:
        return 'Strong';
      case EnginePowerProfile.master:
        return 'Tournament';
      case EnginePowerProfile.max:
        return 'Max';
    }
  }

  String get detailLabel {
    switch (this) {
      case EnginePowerProfile.strong:
        return 'Depth 14';
      case EnginePowerProfile.master:
        return 'Depth 18';
      case EnginePowerProfile.max:
        return 'Adaptive Depth 22-26+';
    }
  }

  String get badgeLabel {
    switch (this) {
      case EnginePowerProfile.strong:
        return 'Recommended';
      case EnginePowerProfile.master:
        return 'Stronger';
      case EnginePowerProfile.max:
        return 'Powerful phones';
    }
  }

  String get supportingText {
    switch (this) {
      case EnginePowerProfile.strong:
        return 'Best for all phones';
      case EnginePowerProfile.master:
        return 'For modern phones';
      case EnginePowerProfile.max:
        return 'May use more battery and take longer';
    }
  }

  String? get infoText {
    switch (this) {
      case EnginePowerProfile.max:
        return 'Max mode uses deeper Stockfish search. Recommended for powerful phones only.';
      case EnginePowerProfile.strong:
      case EnginePowerProfile.master:
        return null;
    }
  }

  bool get isRecommended => this == EnginePowerProfile.strong;
  bool get isHighPower => this == EnginePowerProfile.max;

  EngineSearchConfig resolve({EngineDeviceProfile? device}) {
    final safeDevice = device ?? const EngineDeviceProfile.unknown();

    switch (this) {
      case EnginePowerProfile.strong:
        return EngineSearchConfig(
          profile: this,
          depth: 14,
          skillLevel: 20,
          limitStrength: false,
          ponder: false,
          threads: 1,
          hashMb: 32,
          timeout: const Duration(seconds: 8),
        );
      case EnginePowerProfile.master:
        return EngineSearchConfig(
          profile: this,
          depth: 18,
          skillLevel: 20,
          limitStrength: false,
          ponder: false,
          threads: safeDevice.hasModernHeadroom ? 2 : 1,
          hashMb: safeDevice.isLowRamDevice ? 48 : 64,
          timeout: const Duration(seconds: 10),
        );
      case EnginePowerProfile.max:
        if (safeDevice.isLowRamDevice) {
          return EngineSearchConfig(
            profile: this,
            depth: 22,
            skillLevel: 20,
            limitStrength: false,
            ponder: false,
            threads: 1,
            hashMb: 64,
            timeout: const Duration(seconds: 8),
          );
        }

        if (safeDevice.hasModernHeadroom) {
          return EngineSearchConfig(
            profile: this,
            depth: 26,
            skillLevel: 20,
            limitStrength: false,
            ponder: false,
            threads: 2,
            hashMb: 128,
            timeout: const Duration(seconds: 12),
          );
        }

        return EngineSearchConfig(
          profile: this,
          depth: safeDevice.hasModerateHeadroom ? 24 : 22,
          skillLevel: 20,
          limitStrength: false,
          ponder: false,
          threads: 1,
          hashMb: 64,
          timeout: const Duration(seconds: 10),
        );
    }
  }
}

class EngineSearchConfig {
  final EnginePowerProfile profile;
  final int depth;
  final int skillLevel;
  final bool limitStrength;
  final bool ponder;
  final int threads;
  final int hashMb;
  final Duration timeout;
  final int? moveTimeMs;

  const EngineSearchConfig({
    required this.profile,
    required this.depth,
    required this.skillLevel,
    required this.limitStrength,
    required this.ponder,
    required this.threads,
    required this.hashMb,
    required this.timeout,
    this.moveTimeMs,
  });

  String get goCommand {
    final safeDepth = depth.clamp(1, 30).toInt();
    final safeMoveTime = moveTimeMs?.clamp(100, 5000).toInt();
    if (safeMoveTime == null) return 'go depth $safeDepth';
    return 'go depth $safeDepth movetime $safeMoveTime';
  }
}
