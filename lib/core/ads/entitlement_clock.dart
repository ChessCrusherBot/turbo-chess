import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EntitlementTimeSnapshot {
  final DateTime deviceUtc;
  final DateTime? verifiedServerUtc;
  final int? elapsedRealtimeMillis;

  const EntitlementTimeSnapshot({
    required this.deviceUtc,
    this.verifiedServerUtc,
    this.elapsedRealtimeMillis,
  });

  DateTime get bestAvailableUtc => verifiedServerUtc ?? deviceUtc;

  bool get hasVerifiedServerTime => verifiedServerUtc != null;
}

abstract class EntitlementClock {
  Future<EntitlementTimeSnapshot> snapshot();
}

class DeviceEntitlementClock implements EntitlementClock {
  static const MethodChannel _channel =
      MethodChannel('com.turbochess.app/system_clock');

  const DeviceEntitlementClock();

  @override
  Future<EntitlementTimeSnapshot> snapshot() async {
    final deviceUtc = DateTime.now().toUtc();
    int? elapsedRealtimeMillis;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        elapsedRealtimeMillis =
            await _channel.invokeMethod<int>('elapsedRealtimeMillis');
      } on PlatformException {
        elapsedRealtimeMillis = null;
      } on MissingPluginException {
        elapsedRealtimeMillis = null;
      }
    }

    return EntitlementTimeSnapshot(
      deviceUtc: deviceUtc,
      elapsedRealtimeMillis: elapsedRealtimeMillis,
    );
  }
}
