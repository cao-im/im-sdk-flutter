import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import './connection_manager.dart';
import '../utils/logger.dart';

/// 已读回执管理器（增强版）
///
/// 功能：
/// 1. 批量发送优化（防抖+批量）
/// 2. 网络断开时缓存回执
/// 3. 重连成功后自动补发所有缓存回执
/// 4. 支持最大缓存数量限制
class ReadReceiptManager {
  final ConnectionManager _connectionManager;
  final Duration _batchDelay;
  final Logger _log = AppLogger.instance;

  /// 待发送的已读回执队列
  final Set<int> _pendingReceipts = {};

  /// 定时器（用于批量延迟发送）
  Timer? _batchTimer;

  /// 是否已销毁
  bool _isDisposed = false;

  /// 最大缓存回执数量（防止内存溢出）
  static const int _maxCacheSize = 1000;

  /// 回调：当重连成功时调用此方法触发补发
  VoidCallback? onReconnected;

  ReadReceiptManager({
    required ConnectionManager connectionManager,
    required Duration batchDelay,
    this.onReconnected,
  }) : _connectionManager = connectionManager,
       _batchDelay = batchDelay;

  /// 入队一条已读回执
  Future<void> enqueueReceipt(int messageId, {int? groupId}) async {
    if (_isDisposed) return;

    // 防重复检查
    if (_pendingReceipts.contains(messageId)) return;

    // 超过最大缓存数时强制立即发送
    if (_pendingReceipts.length >= _maxCacheSize) {
      _log.w('⚠️ 已读回执缓存已达上限($_maxCacheSize)，强制立即发送');
      await _sendBatchImmediately();
    }

    _pendingReceipts.add(messageId);
    _scheduleBatchSend();
  }

  /// 批量入队（一次性添加多条）
  Future<void> enqueueBatch(List<int> messageIds) async {
    if (_isDisposed || messageIds.isEmpty) return;

    for (final msgId in messageIds) {
      if (!_pendingReceipts.contains(msgId)) {
        _pendingReceipts.add(msgId);
      }
    }

    // 如果数量较多，缩短延迟时间立即发送
    if (_pendingReceipts.length > 20) {
      await _sendBatchImmediately();
    } else {
      _scheduleBatchSend();
    }
  }

  void _scheduleBatchSend() {
    if (_isDisposed) return;

    _batchTimer?.cancel();
    _batchTimer = Timer(_batchDelay, () {
      if (!_isDisposed && _pendingReceipts.isNotEmpty) {
        _sendBatch();
      }
    });
  }

  Future<void> _sendBatch() async {
    if (_pendingReceipts.isEmpty || _isDisposed) return;

    final messageIds = _pendingReceipts.toList();
    _pendingReceipts.clear();

    try {
      if (_connectionManager.isConnected) {
        _connectionManager.sendMessage({
          'type': 'read_receipt',
          'messageIds': messageIds,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _log.i('✅ 已读回执批量发送成功, 数量=${messageIds.length}, IDs=$messageIds');
      } else {
        // 网络未连接，重新放回缓存队列（等待重连后补发）
        _log.w('📴 网络未连接，已读回执已缓存 (${messageIds.length}条), 等待重连后补发...');
        for (final msgId in messageIds) {
          _pendingReceipts.add(msgId);
        }
      }
    } catch (e) {
      _log.e('❌ 已读回执发送失败, 错误: $e', error: e);
      // 发送失败也放回缓存，等待下次重试
      for (final msgId in messageIds) {
        _pendingReceipts.add(msgId);
      }
    }
  }

  Future<void> _sendBatchImmediately() async {
    _batchTimer?.cancel();
    await _sendBatch();
  }

  /// 🔑 核心功能：重连成功后自动补发所有缓存的回执
  ///
  /// 此方法应在WebSocket重连成功的回调中调用
  Future<void> flushPendingReceipts() async {
    if (_isDisposed || _pendingReceipts.isEmpty) return;

    final cachedCount = _pendingReceipts.length;
    _log.i('🔄 检测到网络恢复, 开始补发缓存的已读回执 ($cachedCount 条)...');

    // 分批发送（避免一次发送过多导致消息过大）
    final batchSize = 50; // 每批最多50条
    final allIds = _pendingReceipts.toList();
    _pendingReceipts.clear();

    int sentCount = 0;
    int failedCount = 0;

    for (int i = 0; i < allIds.length; i += batchSize) {
      final end = (i + batchSize < allIds.length) ? i + batchSize : allIds.length;
      final batch = allIds.sublist(i, end);

      try {
        if (_connectionManager.isConnected) {
          _connectionManager.sendMessage({
            'type': 'read_receipt',
            'messageIds': batch,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'flush': true, // 标记这是补发的回执
          });
          sentCount += batch.length;

          // 批次间间隔50ms，避免过于频繁
          if (end < allIds.length) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } else {
          // 补发过程中又断网了，放回缓存
          _pendingReceipts.addAll(batch);
          failedCount += batch.length;
        }
      } catch (e) {
        _log.e('❌ 补发已读回执失败: $e', error: e);
        _pendingReceipts.addAll(batch); // 失败的放回缓存
        failedCount += batch.length;
      }
    }

    if (sentCount > 0) {
      _log.i('✅ 已读回执补发完成! 成功=$sentCount, 失败=$failedCount, 剩余缓存=${_pendingReceipts.length}');
    } else if (failedCount > 0) {
      _log.w('⚠️ 已读回执全部补发失败 ($failedCount条), 将保留在缓存中等待下次重连');
    }

    // 触发回调通知外部
    onReconnected?.call();
  }

  /// 获取当前缓存的回执数量
  int get pendingCount => _pendingReceipts.length;

  /// 获取调试信息
  Map<String, dynamic> getDebugInfo() {
    return {
      'pendingCount': _pendingReceipts.length,
      'isDisposed': _isDisposed,
      'hasConnectionManager': _connectionManager != null,
      'isConnected': _connectionManager.isConnected,
      'batchDelayMs': _batchDelay.inMilliseconds,
      'maxCacheSize': _maxCacheSize,
    };
  }

  void dispose() {
    _isDisposed = true;
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_pendingReceipts.isNotEmpty) {
      _log.w('ReadReceiptManager 销毁时仍有 ${_pendingReceipts.length} 条待发送回执（将丢失）');
      _pendingReceipts.clear();
    }
  }
}
