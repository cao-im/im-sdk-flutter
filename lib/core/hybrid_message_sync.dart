import 'dart:async';

import 'package:dio/dio.dart';
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
        _log.i('✅ 连接已建立，等待连接稳定后触发离线消息补拉');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && _client.isConnected) {
            _log.i('✅ 连接已稳定，开始离线消息补拉');
            _syncOfflineMessages();
          } else {
            _log.w('⚠️ 连接不稳定，取消离线消息补拉');
          }
        });
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

      // ① 先同步私聊离线消息（原有逻辑）
      final syncState = await MessageSyncState.getSyncState();

      final sinceTimestamp = syncState.lastTimestamp ?? 0;
      final sinceMessageId = syncState.lastMessageId ?? 0;

      _log.i('📋 私聊同步参数: sinceTimestamp=$sinceTimestamp, sinceMessageId=$sinceMessageId');

      await _requestOfflineMessages(
        sinceTimestamp: sinceTimestamp,
        sinceMessageId: sinceMessageId,
      );

      // ② 再同步群聊离线消息（新增）
      await _syncGroupOfflineMessages();

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

  /// 同步群聊离线消息：遍历已加入的群组，按 sinceMid 增量拉取
  Future<void> _syncGroupOfflineMessages() async {
    if (_isDisposed || !_client.isConnected) return;

    try {
      final userId = _client.currentUserId;
      if (userId == null) {
        _log.w('⚠️ 用户未登录，跳过群聊离线同步');
        return;
      }

      // ① 通过 HTTP API 获取用户已加入的所有群组（不走 WebSocket 避免超时）
      final groups = await _fetchUserGroups(userId);
      if (groups.isEmpty) {
        _log.d('用户未加入任何群组，跳过群聊离线同步');
        return;
      }

      _log.i('💬 开始群聊离线消息补拉, 共 ${groups.length} 个群组');

      for (final group in groups) {
        if (_isDisposed || !_client.isConnected) break;

        final groupId = group['id'] ?? group['groupId'];
        if (groupId == null) continue;
        final groupIdInt = groupId is int ? groupId : int.tryParse(groupId.toString()) ?? 0;
        if (groupIdInt <= 0) continue;

        // ② 查询本地该群的最后一条消息 seq（服务端序号，严格递增）
        int sinceSeq = 0;
        try {
          final lastMsg = await _dbHelper.getLastMessage(0, groupId: groupIdInt);
          if (lastMsg != null && lastMsg.seq != null && lastMsg.seq! > 0) {
            sinceSeq = lastMsg.seq!;
          }
        } catch (e) {
          _log.w('查询群$groupIdInt 本地最后消息失败: $e');
        }

        _log.i('📋 群聊离线同步: groupId=$groupIdInt, sinceSeq=$sinceSeq');

        // ③ 发送 WebSocket 请求（响应由 IMClient._handleIncomingMessage 统一处理）
        try {
          _client.connectionManager.sendMessage({
            'type': 'group_offline_sync',
            'groupId': groupIdInt,
            'sinceSeq': sinceSeq,
            'limit': _batchSize,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          // 等待一小段时间，避免请求过于密集
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log.w('发送群$groupIdInt 离线同步请求失败: $e');
        }
      }

      _log.i('✅ 群聊离线消息补拉请求已全部发出');
    } catch (e) {
      _log.e('群聊离线消息同步异常（非致命）: $e');
      // 不影响私聊离线同步结果，静默忽略
    }
  }

  /// 通过 HTTP API 获取用户已加入的群组列表
  Future<List<Map<String, dynamic>>> _fetchUserGroups(int userId) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      final httpBaseUrl = _convertToHttpUrl(_client.serverUrl);

      final response = await dio.get(
        '$httpBaseUrl/api/group/list',
        queryParameters: {'userId': userId},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_client.token}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['code'] == 200 && data['data'] != null) {
          final list = data['data'];
          if (list is List) {
            return list.cast<Map<String, dynamic>>();
          }
        }
      }
      return [];
    } catch (e) {
      _log.w('HTTP 获取用户群组列表失败（非致命）: $e');
      return [];
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
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: _requestTimeoutSeconds);
      dio.options.receiveTimeout = const Duration(seconds: _requestTimeoutSeconds);

      // 将WebSocket URL转换为HTTP REST API URL
      // 例如: ws://localhost:8080/ws → http://localhost:8080/api
      final httpBaseUrl = _convertToHttpUrl(_client.serverUrl);

      _log.i('🌐 HTTP请求地址: $httpBaseUrl/message/offline');

      final response = await dio.get(
        '$httpBaseUrl/api/message/offline',
        queryParameters: {
          // 注意：userId不再需要传！服务端从JWT Token中自动提取
          'since': sinceTimestamp,
          'sinceMessageId': sinceMessageId,
          'offset': offset,
          'limit': limit,
        },
        options: Options(
          headers: {
            // 必须携带有效的JWT Token，服务端会从中提取userId
            'Authorization': 'Bearer ${_client.token}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data == null || data is! Map) {
          _log.w('⚠️ HTTP返回数据为空或格式异常: statusCode=${response.statusCode}, data=$data, raw=${response.toString()}');
          return [];
        }

        if (data['code'] == 200 && data['data'] != null) {
          final responseData = data['data'] as Map<String, dynamic>;
          final messages = responseData['messages'] as List? ?? [];

          _log.i('📥 HTTP离线消息请求成功: 返回${messages.length}条');

          return messages.cast<Map<String, dynamic>>();
        } else {
          _log.w('⚠️ HTTP返回异常: code=${data['code']}, message=${data['message']}');
          return [];
        }
      } else {
        _log.w('⚠️ HTTP请求失败: statusCode=${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _log.w('HTTP请求超时');
      } else {
        _log.e('HTTP请求异常', error: e);
      }
      return [];
    } catch (e) {
      _log.e('获取离线消息失败', error: e);
      return [];
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

        // 离线消息拉取后自动发送送达回执，标记已送达（避免下次重连重复拉取）
        if (message.mid != null && message.mid! > 0) {
          _client.sendDeliveryAck(message.mid!);
        }

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

  /// 将WebSocket URL转换为HTTP REST API基础URL
  /// 例如:
  ///   - ws://localhost:8080/ws → http://localhost:8080
  ///   - wss://example.com/ws → https://example.com
  ///   - localhost:8080 → http://localhost:8080
  String _convertToHttpUrl(String wsUrl) {
    try {
      final uri = Uri.parse(wsUrl);

      // 提取协议、主机、端口
      String scheme = uri.scheme;
      String host = uri.host;
      int? port = uri.port;

      // 处理协议转换
      if (scheme == 'ws') {
        scheme = 'http';
      } else if (scheme == 'wss') {
        scheme = 'https';
      } else if (scheme.isEmpty || scheme == 'http' || scheme == 'https') {
        // 已经是HTTP协议或没有协议，保持不变
        if (scheme.isEmpty) {
          scheme = 'http';
        }
      }

      // 构建基础URL（不包含路径部分）
      String baseUrl;
      if (port != null && port > 0 && port != 80 && port != 443) {
        baseUrl = '$scheme://$host:$port';
      } else {
        baseUrl = '$scheme://$host';
      }

      _log.d('🔀 URL转换: $wsUrl → $baseUrl');
      return baseUrl;
    } catch (e) {
      _log.w('⚠️ URL转换失败: $wsUrl, 错误: $e');
      // 如果转换失败，尝试简单的字符串替换作为fallback
      return wsUrl
          .replaceAll('ws://', 'http://')
          .replaceAll('wss://', 'https://')
          .replaceAll(RegExp(r'/ws$'), '')
          .replaceAll(RegExp(r'/ws/$'), '');
    }
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
