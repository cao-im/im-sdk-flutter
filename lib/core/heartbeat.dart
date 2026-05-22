import 'dart:async';

class HeartbeatManager {
  Timer? _timer;
  bool _isRunning = false;
  final int intervalSeconds;
  final VoidCallback onPing;
  final VoidCallback onTimeout;

  int _lastResponseTime = 0;
  int _timeoutThreshold = 45000;

  HeartbeatManager({
    required this.intervalSeconds,
    required this.onPing,
    required this.onTimeout,
  });

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _lastResponseTime = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _checkAndSendPing(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void _checkAndSendPing() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastResponseTime > _timeoutThreshold) {
      onTimeout();
      return;
    }
    onPing();
  }

  void onResponseReceived() {
    _lastResponseTime = DateTime.now().millisecondsSinceEpoch;
  }

  void dispose() {
    stop();
  }
}

typedef VoidCallback = void Function();
