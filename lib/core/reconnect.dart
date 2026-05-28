import 'dart:async';

import '../utils/logger.dart';

typedef DelayCalculator = int Function(int retryCount);

class ReconnectManager {
  Timer? _reconnectTimer;
  bool _isReconnecting = false;
  int _retryCount = 0;
  
  final int maxRetries;
  final bool infiniteRetry;
  final int baseDelayMs;
  final int maxDelayMs;
  final DelayCalculator? delayCalculator;
  final Future<bool> Function() onReconnect;
  final VoidCallback onReconnectSuccess;
  final VoidCallback onReconnectFailed;
  final VoidCallbackFunction onStatusChange;
  final ReconnectInfoCallback? onReconnectAttempt;

  final Logger _log = AppLogger.instance;

  ReconnectManager({
    this.maxRetries = 5,
    this.infiniteRetry = false,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.delayCalculator,
    required this.onReconnect,
    required this.onReconnectSuccess,
    required this.onReconnectFailed,
    required this.onStatusChange,
    this.onReconnectAttempt,
  });

  bool get isReconnecting => _isReconnecting;
  int get retryCount => _retryCount;
  bool get canRetry => infiniteRetry || _retryCount < maxRetries;
  int get remainingRetries => infiniteRetry ? -1 : (maxRetries - _retryCount);
  
  String get statusDescription {
    if (_isReconnecting) {
      return '正在重连中 (第 ${_retryCount + 1} 次, 延迟: ${_getNextDelay()}ms)';
    } else if (_retryCount == 0) {
      return '就绪 (尚未重试)';
    } else if (!canRetry) {
      return '已耗尽重试次数 ($_retryCount/$maxRetries)';
    } else {
      return '已停止 (已重试 $_retryCount 次, 剩余 $remainingRetries 次)';
    }
  }

  Future<void> scheduleReconnect({String? reason}) async {
    if (_isReconnecting) {
      _log.d('⏭️ 跳过重连请求: 正在重连中');
      return;
    }

    if (!infiniteRetry && _retryCount >= maxRetries) {
      _log.w('❌ 无法重连: 已达最大重试次数 ($maxRetries)');
      return;
    }

    _isReconnecting = true;
    
    final delay = _calculateDelay();
    final attemptInfo = ReconnectAttemptInfo(
      attemptNumber: _retryCount + 1,
      delay: delay,
      reason: reason ?? '连接断开',
      timestamp: DateTime.now(),
    );
    
    _log.i('🔄 计划重连 #${attemptInfo.attemptNumber}');
    _log.i('   原因: ${attemptInfo.reason}');
    _log.i('   延迟: ${delay}ms (${delay / 1000}秒)');
    if (!infiniteRetry) {
      _log.i('   进度: ${attemptInfo.attemptNumber}/$maxRetries');
    } else {
      _log.i('   模式: 无限重试');
    }
    
    onStatusChange(true);
    onReconnectAttempt?.call(attemptInfo);

    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      await _executeReconnect(attemptInfo);
    });
  }

  Future<void> _executeReconnect(ReconnectAttemptInfo attemptInfo) async {
    _log.i('🔁 执行重连 #${attemptInfo.attemptNumber}...');
    final startTime = DateTime.now();
    
    try {
      _retryCount++;
      
      _log.i('   调用 onReconnect() 回调...');
      final success = await onReconnect();
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      if (success) {
        _log.i('✅ 重连成功! 耗时: ${duration}ms, 总共尝试: $_retryCount 次');
        _resetState();
        onReconnectSuccess();
      } else {
        _log.w('⚠️ 重连失败: onReconnect() 返回 false, 耗时: ${duration}ms');
        
        if (canRetry) {
          _log.i('📋 将在 ${_getNextDelay()}ms 后进行第 ${_retryCount + 1} 次重连...');
          _isReconnecting = false;
          await scheduleReconnect(reason: '上次重连返回失败');
        } else {
          _log.e('❌ 重连失败且已达最大次数 ($maxRetries)，放弃重连');
          _resetState();
          onReconnectFailed();
        }
      }
    } catch (e, stack) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _log.e('❌ 重连异常: $e', error: e);
      _log.e('   耗时: ${duration}ms');
      _log.e('   StackTrace: $stack');
      
      if (canRetry) {
        _log.i('📋 将在 ${_getNextDelay()}ms 后进行第 ${_retryCount + 1} 次重连...');
        _isReconnecting = false;
        await scheduleReconnect(reason: '异常: ${e.toString()}');
      } else {
        _log.e('❌ 重连异常且已达最大次数 ($maxRetries)，放弃重连');
        _resetState();
        onReconnectFailed();
      }
    }
  }

  void cancel() {
    if (_reconnectTimer != null) {
      _log.d('🛑 取消重连定时器 (原计划在第 ${_retryCount + 1} 次)');
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
    _isReconnecting = false;
    onStatusChange(false);
  }

  void reset({bool logReset = true}) {
    if (logReset && _retryCount > 0) {
      _log.i('🔄 重置重连状态 (之前已重试 $_retryCount 次)');
    }
    cancel();
    _retryCount = 0;
  }

  int _calculateDelay() {
    if (delayCalculator != null) {
      final customDelay = delayCalculator!(_retryCount);
      final cappedDelay = customDelay > maxDelayMs ? maxDelayMs : customDelay;
      if (customDelay != cappedDelay) {
        _log.d('自定义延迟 ${customDelay}ms 超过最大值，限制为 ${maxDelayMs}ms');
      }
      return cappedDelay;
    }
    
    if (_retryCount <= 0) return baseDelayMs;
    
    final exponentialDelay = baseDelayMs * (1 << (_retryCount - 1));
    return exponentialDelay > maxDelayMs ? maxDelayMs : exponentialDelay;
  }

  int _getNextDelay() {
    if (delayCalculator != null) {
      return delayCalculator!(_retryCount + 1);
    }
    
    if (_retryCount <= 0) return baseDelayMs;
    
    final nextDelay = baseDelayMs * (1 << _retryCount);
    return nextDelay > maxDelayMs ? maxDelayMs : nextDelay;
  }

  void _resetState() {
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    onStatusChange(false);
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'isReconnecting': _isReconnecting,
      'retryCount': _retryCount,
      'maxRetries': maxRetries,
      'infiniteRetry': infiniteRetry,
      'canRetry': canRetry,
      'remainingRetries': remainingRetries,
      'currentDelay': _calculateDelay(),
      'nextDelay': _getNextDelay(),
      'baseDelayMs': baseDelayMs,
      'maxDelayMs': maxDelayMs,
      'hasCustomDelayCalculator': delayCalculator != null,
      'statusDescription': statusDescription,
    };
  }

  void dispose() {
    _log.d('🗑️ 销毁 ReconnectManager');
    cancel();
  }
}

class ReconnectAttemptInfo {
  final int attemptNumber;
  final int delay;
  final String reason;
  final DateTime timestamp;

  ReconnectAttemptInfo({
    required this.attemptNumber,
    required this.delay,
    required this.reason,
    required this.timestamp,
  });

  @override
  String toString() => 'ReconnectAttemptInfo(#$attemptNumber, delay: ${delay}ms, reason: $reason)';
}

typedef VoidCallback = void Function();
typedef VoidCallbackFunction = void Function(bool isReconnecting);
typedef ReconnectInfoCallback = void Function(ReconnectAttemptInfo info);