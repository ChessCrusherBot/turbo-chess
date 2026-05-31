import 'package:flutter/foundation.dart';

class AppFlags {
  const AppFlags._();

  static const bool adsEnabled = bool.fromEnvironment(
    'TURBO_CHESS_ENABLE_ADS',
    defaultValue: kReleaseMode,
  );
}
