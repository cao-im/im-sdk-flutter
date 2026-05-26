import 'dart:async';

import '../client/im_client.dart';
import '../model/message.dart';
import '../storage/storage_interface.dart';
import '../event/event_bus.dart';
import '../event/im_event.dart';
import '../utils/logger.dart';
import 'message_sync_state.dart';
import 'connection_status.dart';

class HybridMessageSync {
  final IMClient _client;
  final StorageInterface _dbHelper;
  final EventBus _eventBus;

  SyncMode _currentMode = SyncMode.realtime;
  Timer? _fallbackTimer;
  bool _isSyncing = false;
  StreamSubscription? _connectionSub;
  StreamSubscription? _messageSub;
  Completer<List<Map<String, dynamic>>>? _currentRequest;
  int _totalSyncedCount = 0;
  int _consecutiveErrors = 0;
  bool _isDisposed = false;

  static const int _batchSize = 50;
  static const int _requestTimeoutSeconds = 10;
  static const int _maxConsecutiveErrors = 3;
  static const Duration _errorBackoffDelay = Duration(seconds: 5);
  static const int _fallbackIntervalMs = 60000;

  final Logger _log = AppLogger.instance;

  HybridMessageSync({
    required IMClient client,
    required StorageInterface dbHelper,
    required EventBus eventBus,
  }) : _client = client,
       _dbHelper = dbHelper,
       _eventBus = eventBus;

  SyncMode get currentMode => _currentMode;
  bool get isSyncing => _isSyncing;
  int get totalSyncedCount => _totalSyncedCount;

  void start() {
    if (_isDisposed) return;
    stop();
    _log.i('🚀 混合消息同步服务已启动 (微信模式)');
    _setupEventListeners();
    _switchToRealtimeMode();
  }

  void stop() {
    _stopFallbackTimer();
    _connectionSub?.cancel();
    _connectionSub = null;
    _messageSub?.cancel();
    _messageSub = null;
    _currentRequest = null;
    _log.i('混合消息同步服务已停止');
  }

  void _setupEventListeners() {
    _connectionSub = _client.connectionManager.onStatusChanged.listen((status) {
      _handleConnectionStatusChange(status);
    });
  }

  void _handleConnectionStatusChange(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        _log.i('✅ 连接已建立，触发离线消息补拉');
        _syncOfflineMessages();
        break;
      case ConnectionStatus.disconnected:
        _log.w('⚠️ 连接断开，准备切换到降级模式');
        _switchToFallbackMode();
        break;
      case ConnectionStatus.reconnecting:
        _log.i('🔄 正在重连...');
        break;
      default:
        break;
    }
  }

  void _switchToRealtimeMode() {
    if (_currentMode == SyncMode.realtime) return;
    _currentMode = SyncMode.realtime;
    _stopFallbackTimer();
    _consecutiveErrors = 0;
    _log.i('✨ 已切换到实时推送模式 (主通道)');
    _eventBus.fire(SyncModeChangedEvent(
      from: _currentMode,
      to: SyncMode.realtime,
      reason: 'WebSocket连接正常',
    ));
  }

  void _switchToFallbackMode() {
    if (_currentMode == SyncMode.fallback) return;
    _currentMode = SyncMode.fallback;
    _startFallbackTimer();
    _log.i('⚠️ 已切换到轮询降级模式 (备用通道)');
    _eventBus.fire(SyncModeChangedEvent(
      from: SyncMode.realtime,
      to: SyncMode.fallback,
      reason: 'WebSocket连接断开',
    ));
  }

  void _startFallbackTimer() {
    _stopFallbackTimer();
    _fallbackTimer = Timer.periodic(
      Duration(milliseconds: _fallbackIntervalMs),
      (_) => _syncOfflineMessages(),
    );
    _log.i('⏰ 降级轮询已启动, 间隔: ${_fallbackIntervalMs / 1000}秒');
  }

  void _stopFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  Future<void> syncNow() async {
    if (_isDisposed || _isSyncing) {
      _log.d('跳过同步: disposed=$_isDisposed, syncing=$_isSyncing');
      return;
    }
    await _syncOfflineMessages();
  }

  Future<void> _syncOfflineMessages() async {
    if (_isDisposed || _isSyncing || !_client.isConnected) return;

    _isSyncing = true;
    _totalSyncedCount = 0;

    try {
      _log.i('💡 开始离线消息补拉 (微信模式)...');

      final syncState = await MessageSyncState.getSyncState();

      final sinceTimestamp = syncState.lastTimestamp ?? 0;
      final sinceMessageId = syncState.lastMessageId ?? 0;

      _log.i('📋 同步参数: sinceTimestamp=$sinceTimestamp, sinceMessageId=$sinceMessageId');

      await _requestOfflineMessages(
        sinceTimestamp: sinceTimestamp,
        sinceMessageId: sinceMessageId,
      );

      await MessageSyncState.updateLastSyncTime(DateTime.now().millisecondsSinceEpoch);

      _consecutiveErrors = 0;

      _log.i('✅ 离线消息补拉完成, 共同步 $_totalSyncedCount 条消息');
      _eventBus.fire(OfflineSyncCompletedEvent(
        totalSynced: _totalSyncedCount,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    } on TimeoutException catch (e) {
      _consecutiveErrors++;
      _log.e('离线消息同步超时 ($_consecutiveErrors/$_maxConsecutiveErrors)', error: e);
      _handleConsecutiveErrors();
    } catch (e) {
      _consecutiveErrors++;
      _log.e('离线消息同步失败 ($_consecutiveErrors/$_maxConsecutiveErrors)', error: e);
      _handleConsecutiveErrors();
      _eventBus.fire(OfflineSyncFailedEvent(
        error: e.toString(),
        retryCount: _consecutiveErrors,
      ));
    } finally {
      _isSyncing = false;
      _currentRequest = null;
    }
  }

  void _handleConsecutiveErrors() {
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      _log.w('连续错误次数已达上限，延长同步间隔');
      stop();
      Timer(_errorBackoffDelay * _consecutiveErrors, () {
        if (!_isDisposed && _client.isConnected) {
          start();
          _log.i('恢复同步服务');
        }
      });
    }
  }

  Future<void> _requestOfflineMessages({
    required int sinceTimestamp,
    required int sinceMessageId,
  }) async {
    bool hasMore = true;
    int offset = 0;
    int batchNum = 0;

    while (hasMore && !_isDisposed) {
      batchNum++;
      try {
        final messages = await _fetchOfflineBatch(
          sinceTimestamp: sinceTimestamp,
          sinceMessageId: sinceMessageId,
          offset: offset,
          limit: _batchSize,
        );

        if (messages.isEmpty) {
          hasMore = false;
          _log.d('批次 #$batchNum: 无更多离线消息');
          break;
        }

        _log.i('批次 #$batchNum: 收到 ${messages.length} 条离线消息');

        final processedCount = await _processMessages(messages);
        _totalSyncedCount += processedCount;

        offset += messages.length;

        final maxMessageId = _getMaxMessageId(messages);
        if (maxMessageId > sinceMessageId) {
          await MessageSyncState.updateLastMessageId(maxMessageId);
        }

        if (messages.length < _batchSize) {
          hasMore = false;
          _log.d('批次 #$batchNum: 返回数量少于请求量，结束拉取');
        }

        await Future.delayed(const Duration(milliseconds: 50));
      } on TimeoutException catch (e) {
        _log.w('批次 #$batchNum 请求超时', error: e);
        hasMore = false;
      } catch (e) {
        _log.e('批次 #$batchNum 拉取失败', error: e);
        hasMore = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOfflineBatch({
    required int sinceTimestamp,
    required int sinceMessageId,
    required int offset,
    required int limit,
  }) async {
    if (_currentRequest != null && !_currentRequest!.isCompleted) {
      throw StateError('已有进行中的请求');
    }

    _currentRequest = Completer<List<Map<String, dynamic>>>();

    StreamSubscription? sub;
    sub = _eventBus.on<OfflineMessagesEvent>().listen((event) {
      if (_currentRequest != null && !_currentRequest!.isCompleted) {
        _currentRequest!.complete(event.messages);
      }
      sub?.cancel();
    });

    try {
      _client.connectionManager?.sendMessage({
        'type': 'get_offline_messages',
        'since': sinceTimestamp,
        'sinceMessageId': sinceMessageId,
        'offset': offset,
        'limit': limit,
      });

      final result = await _currentRequest!.future.timeout(
        Duration(seconds: _requestTimeoutSeconds),
        onTimeout: () => [],
      );

      return result;
    } finally {
      sub?.cancel();
    }
  }

  Future<int> _processMessages(List<Map<String, dynamic>> messagesJson) async {
    int processedCount = 0;
    final uniqueIds = <int>{};

    for (final msgJson in messagesJson) {
      try {
        final message = Message.fromJson(msgJson);

        if (message.id == null || uniqueIds.contains(message.id)) {
          continue;
        }
        uniqueIds.add(message.id!);

        final existing = await _getMessageById(message.id!);
        if (existing != null) {
          continue;
        }

        await _dbHelper.insertMessage(message);

        for (final listener in _client.messageListeners) {
          listener.onMessageReceived(message);
        }
        _eventBus.fire(MessageReceivedEvent(message: message));

        await _updateConversationFromMessage(message);

        processedCount++;
      } catch (e) {
        _log.w('处理单条消息失败: $e');
      }
    }

    return processedCount;
  }

  Future<Message?> _getMessageById(int messageId) async {
    try {
      return await _dbHelper.getMessageById(messageId);
    } catch (e) {
      _log.e('查询消息失败, messageId=$messageId', error: e);
      return null;
    }
  }

  int _getMaxMessageId(List<Map<String, dynamic>> messages) {
    int maxId = 0;
    for (final msg in messages) {
      final id = msg['id'];
      if (id is int && id > maxId) {
        maxId = id;
      }
    }
    return maxId;
  }

  Future<void> _updateConversationFromMessage(Message message) async {
    if (_client.currentUserId == null) return;

    final isPrivate = message.groupId == null;
    final targetType = isPrivate ? 1 : 2;
    final targetId = isPrivate
        ? (message.fromId == _client.currentUserId
              ? message.toId
              : message.fromId)
        : message.groupId!;

    try {
      final conversationService = _client.conversationService;
      final existingConversation = await conversationService
          .getOrCreateConversation(
            userId: _client.currentUserId!,
            targetType: targetType,
            targetId: targetId,
          );

      final updatedConversation = existingConversation.copyWith(
        lastMessage: message,
        updateTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: message.fromId != _client.currentUserId
            ? existingConversation.unreadCount + 1
            : existingConversation.unreadCount,
      );

      if (existingConversation.id != null) {
        await conversationService.updateLastMessage(
          existingConversation.id!,
          message,
        );

        if (message.fromId != _client.currentUserId) {
          await conversationService.incrementUnreadCount(
            existingConversation.id!,
            count: 1,
          );
        }
      }

      _eventBus.fire(
        ConversationUpdatedEvent(conversation: updatedConversation),
      );
    } catch (e) {
      _log.e('更新会话失败: $e', error: e);
    }
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'currentMode': _currentMode.name,
      'isSyncing': _isSyncing,
      'totalSyncedCount': _totalSyncedCount,
      'consecutiveErrors': _consecutiveErrors,
      'isDisposed': _isDisposed,
      'isFallbackActive': _fallbackTimer != null,
    };
  }

  void dispose() {
    _isDisposed = true;
    stop();
    _log.i('HybridMessageSync 已释放资源');
  }
}
