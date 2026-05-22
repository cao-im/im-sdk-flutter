import 'dart:async';

class ReconnectManager {
  Timer? _reconnectTimer;
  bool _isReconnecting = false;
  int _retryCount = 0;
  final int maxRetries;
  final int baseDelayMs;
  final int maxDelayMs;
  final Future<bool> Function() onReconnect;
  final VoidCallback onReconnectSuccess;
  final VoidCallback onReconnectFailed;
  final VoidCallbackFunction onStatusChange;

  ReconnectManager({
    this.maxRetries = 5,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 30000,
    required this.onReconnect,
    required this.onReconnectSuccess,
    required this.onReconnectFailed,
    required this.onStatusChange,
  });

  bool get isReconnecting => _isReconnecting;
  int get retryCount => _retryCount;

  Future<void> scheduleReconnect() async {
    if (_isReconnecting || _retryCount >= maxRetries) return;

    _isReconnecting = true;
    onStatusChange(true);

    final delay = _calculateDelay();

    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      try {
        _retryCount++;
        final success = await onReconnect();

        if (success) {
          _resetState();
          onReconnectSuccess();
        } else if (_retryCount < maxRetries) {
          await scheduleReconnect();
        } else {
          _resetState();
          onReconnectFailed();
        }
      } catch (e) {
        if (_retryCount < maxRetries) {
          await scheduleReconnect();
        } else {
          _resetState();
          onReconnectFailed();
        }
      }
    });
  }

  void cancel() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
    onStatusChange(false);
  }

  void reset() {
    cancel();
    _retryCount = 0;
  }

  int _calculateDelay() {
    final delay = baseDelayMs * (1 << (_retryCount - 1));
    return delay > maxDelayMs ? maxDelayMs : delay;
  }

  void _resetState() {
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    onStatusChange(false);
  }

  void dispose() {
    cancel();
  }
}

typedef VoidCallback = void Function();
typedef VoidCallbackFunction = void Function(bool isReconnecting);
