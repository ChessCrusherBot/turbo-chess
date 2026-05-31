import 'dart:async';
import 'dart:io';

/// Simple offline connectivity checker
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = false;

  Stream<bool> get connectivityStream => _controller.stream;
  bool get isOnline => _isOnline;

  Future<void> check() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (wasOnline != _isOnline) {
        _controller.add(_isOnline);
      }
    } catch (_) {
      final wasOnline = _isOnline;
      _isOnline = false;
      if (wasOnline) {
        _controller.add(false);
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}
