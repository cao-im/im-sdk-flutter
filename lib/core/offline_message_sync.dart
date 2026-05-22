import 'dart:async';

import '../client/im_client.dart';
import '../model/message.dart';
import '../storage/database_helper.dart';
import '../event/event_bus.dart';
import '../event/im_event.dart';
import '../utils/logger.dart';
import 'message_sync_state.dart';

class OfflineMessageSync {
  final IMClient _client;
  final DatabaseHelper _dbHelper;
  final EventBus _eventBus;

  Timer? _syncTimer;
  bool _isSyncing = false;
  int? _lastSyncTimestamp;
  StreamSubscription? _offlineEventSub;
  Completer<List<Map<String, dynamic>>>? _currentRequest;

  static const int _syncIntervalMs = 30000;
  static const int _batchSize = 50;
  static const int _requestTimeoutSeconds = 10;
  static const int _maxConsecutiveErrors = 3;
  static const Duration _errorBackoffDelay = Duration(seconds: 5);

  int _consecutiveErrorCount = 0;
  bool _isDisposed = false;
  int _totalSyncedCount = 0;

  final Logger _log = AppLogger.instance;

  OfflineMessageSync({
    required IMClient client,
    required DatabaseHelper dbHelper,
    required EventBus eventBus,
  }) : _client = client,
       _dbHelper = dbHelper,
       _eventBus = eventBus;

  void start() {
    if (_isDisposed) return;
    stop();
    _log.i('离线消息同步服务已启动, 同步间隔: ${_syncIntervalMs / 1000}秒');
    _syncTimer = Timer.periodic(
      Duration(milliseconds: _syncIntervalMs),
      (_) => checkAndSync(),
    );
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _offlineEventSub?.cancel();
    _offlineEventSub = null;
    _currentRequest = null;
    _log.i('离线消息同步服务已停止');
  }

  Future<void> syncNow() async {
    if (_isDisposed || _isSyncing) {
      _log.d('跳过同步: disposed=$_isDisposed, syncing=$_isSyncing');
      return;
    }

    _isSyncing = true;
    _totalSyncedCount = 0;

    try {
      _log.i('开始离线消息同步...');

      final syncState = await MessageSyncState.getSyncState();

      final sinceTimestamp = syncState.lastTimestamp ?? _lastSyncTimestamp ?? 0;
      final sinceMessageId = syncState.lastMessageId ?? 0;

      _log.i(
        '同步参数: sinceTimestamp=$sinceTimestamp, sinceMessageId=$sinceMessageId',
      );

      await _requestOfflineMessages(
        sinceTimestamp: sinceTimestamp,
        sinceMessageId: sinceMessageId,
      );

      _lastSyncTimestamp = DateTime.now().millisecondsSinceEpoch;

      await MessageSyncState.updateLastSyncTime(_lastSyncTimestamp!);

      _consecutiveErrorCount = 0;

      _log.i('离线消息同步完成, 共同步 $_totalSyncedCount 条消息');
      _eventBus.fire(
        OfflineSyncCompletedEvent(
          totalSynced: _totalSyncedCount,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } on TimeoutException catch (e) {
      _consecutiveErrorCount++;
      _log.e(
        '离线消息同步超时 ($_consecutiveErrorCount/$_maxConsecutiveErrors)',
        error: e,
      );
      _handleConsecutiveErrors();
    } catch (e) {
      _consecutiveErrorCount++;
      _log.e(
        '离线消息同步失败 ($_consecutiveErrorCount/$_maxConsecutiveErrors)',
        error: e,
      );
      _handleConsecutiveErrors();
      _eventBus.fire(
        OfflineSyncFailedEvent(
          error: e.toString(),
          retryCount: _consecutiveErrorCount,
        ),
      );
    } finally {
      _isSyncing = false;
      _currentRequest = null;
    }
  }

  void _handleConsecutiveErrors() {
    if (_consecutiveErrorCount >= _maxConsecutiveErrors) {
      _log.w('连续错误次数已达上限，延长同步间隔');
      stop();
      Timer(_errorBackoffDelay * _consecutiveErrorCount, () {
        if (!_isDisposed && _client.isConnected) {
          start();
          _log.i('恢复定时同步');
        }
      });
    }
  }

  Future<void> checkAndSync() async {
    if (!_client.isConnected || _isSyncing || _isDisposed) return;
    await syncNow();
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
      final db = await _dbHelper.database;
      final maps = await db.query(
        'messages',
        where: 'id = ?',
        whereArgs: [messageId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Message.fromJson({
          'id': maps.first['id'],
          'fromId': maps.first['from_id'],
          'toId': maps.first['to_id'],
          'groupId': maps.first['group_id'],
          'content': maps.first['content'],
          'msgType': maps.first['msg_type'],
          'status': maps.first['status'],
          'timestamp': maps.first['timestamp'],
          'localPath': maps.first['local_path'],
        });
      }
      return null;
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

  bool get isSyncing => _isSyncing;
  int get totalSyncedCount => _totalSyncedCount;

  void dispose() {
    _isDisposed = true;
    stop();
    _log.i('OfflineMessageSync 已释放资源');
  }
}
