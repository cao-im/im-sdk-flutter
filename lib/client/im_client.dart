import 'dart:async';

import '../core/connection_manager.dart';
import '../core/connection_status.dart';
import '../core/offline_message_sync.dart';
import '../core/reconnect.dart';
import '../core/user_status_manager.dart';
import '../event/event_bus.dart';
import '../event/event_listener.dart';
import '../event/im_event.dart';
import '../model/message.dart';
import '../model/conversation.dart';
import '../model/group.dart';
import '../model/user.dart';
import '../storage/database_helper.dart';
import '../utils/logger.dart';
import '../service/message_service_impl.dart';
import '../service/conversation_service_impl.dart';
import '../service/group_service_impl.dart';

class IMConfig {
  final int heartbeatInterval;
  final int reconnectMaxRetries;
  final int reconnectBaseDelayMs;
  final int connectTimeoutSeconds;
  final bool enableOfflineSync;

  const IMConfig({
    this.heartbeatInterval = 30,
    this.reconnectMaxRetries = 5,
    this.reconnectBaseDelayMs = 1000,
    this.connectTimeoutSeconds = 10,
    this.enableOfflineSync = true,
  });

  IMConfig copyWith({
    int? heartbeatInterval,
    int? reconnectMaxRetries,
    int? reconnectBaseDelayMs,
    int? connectTimeoutSeconds,
    bool? enableOfflineSync,
  }) {
    return IMConfig(
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      reconnectMaxRetries: reconnectMaxRetries ?? this.reconnectMaxRetries,
      reconnectBaseDelayMs: reconnectBaseDelayMs ?? this.reconnectBaseDelayMs,
      connectTimeoutSeconds:
          connectTimeoutSeconds ?? this.connectTimeoutSeconds,
      enableOfflineSync: enableOfflineSync ?? this.enableOfflineSync,
    );
  }
}

class IMClient {
  static const int _expectedPort = 80;

  static IMClient? _instance;
  static IMConfig _defaultConfig = const IMConfig();

  static IMClient get instance {
    _instance ??= IMClient._internal();
    return _instance!;
  }

  static set defaultConfig(IMConfig config) {
    _defaultConfig = config;
  }

  final Logger _log = AppLogger.instance;

  IMClient._internal();

  late String serverUrl;
  late String token;
  int? currentUserId;
  bool _isInitialized = false;
  late IMConfig _config;

  late ConnectionManager _connectionManager;
  late EventBus _eventBus;
  late DatabaseHelper _dbHelper;

  late MessageServiceImpl _messageService;
  late ConversationServiceImpl _conversationService;
  late GroupServiceImpl _groupService;
  UserStatusManager? _userStatusManager;
  OfflineMessageSync? _offlineSync;

  final List<MessageListener> _messageListeners = [];
  final List<ConnectionListener> _connectionListeners = [];

  StreamSubscription? _connectionSub;
  StreamSubscription? _messageSub;
  StreamSubscription? _reconnectSub;
  ReconnectManager? _reconnectManager;

  MessageServiceImpl get messageService => _messageService;
  ConversationServiceImpl get conversationService => _conversationService;
  GroupServiceImpl get groupService => _groupService;
  UserStatusManager? get userStatusManager => _userStatusManager;
  EventBus get eventBus => _eventBus;
  DatabaseHelper get database => _dbHelper;
  ConnectionManager get connectionManager => _connectionManager;
  IMConfig get config => _config;
  List<MessageListener> get messageListeners =>
      List.unmodifiable(_messageListeners);

  Future<void> init({required String serverUrl, IMConfig? config}) async {
    if (_isInitialized) return;

    _config = config ?? _defaultConfig;

    final uri = Uri.parse(serverUrl);
    if (uri.hasPort && uri.port != _expectedPort) {
      throw ArgumentError(
        'IM SDK 端口必须为 $_expectedPort，不允许使用其他端口。当前请求端口: ${uri.port}\n\n'
        '========================================\n'
        '曹操IM (Cao-IM) SDK 端口安全限制\n'
        '========================================\n\n'
        '服务端端口已硬编码锁定，此设计目的:\n'
        '1. 确保客户端与服务端端口一致\n'
        '2. 防止配置错误导致连接失败\n'
        '3. 简化部署流程，减少配置项\n\n'
        '正确用法:\n'
        '  ✅ IMClient().init(serverUrl: \'ws://your-server.com/api/ws\');\n'
        '  ✅ IMClient().init(serverUrl: \'ws://your-server.com:$_expectedPort/api/ws\');\n\n'
        '错误用法:\n'
        '  ❌ IMClient().init(serverUrl: \'ws://your-server.com:9090/api/ws\');\n'
        '  ❌ IMClient().init(serverUrl: \'ws://your-server.com:8081/api/ws\');\n\n'
        '如需更改端口（需要修改源码并重新编译）:\n'
        '- 服务端: ImServerApplication.java -> FORCED_PORT\n'
        '- 服务端: PortBindingValidator.java -> EXPECTED_PORT\n'
        '- SDK: im_client.dart -> _expectedPort\n'
        '- SDK: connection_manager.dart -> _expectedPort\n\n'
        '⚠️ 重要提示:\n'
        '即使修改了源码，SDK 连接时还会进行运行时验证。\n'
        '如果服务端端口与 SDK 不匹配，连接将被拒绝。\n'
        '这是协议级别的保护，不仅仅是代码层面的限制。',
      );
    }

    this.serverUrl = uri.replace(port: _expectedPort).toString();
    _connectionManager = ConnectionManager();
    _eventBus = EventBus();
    _dbHelper = DatabaseHelper();
    await _dbHelper.database;

    _initServices();
    _setupEventHandlers();
    _isInitialized = true;
  }

  void _initServices() {
    _messageService = MessageServiceImpl(
      connectionManager: _connectionManager,
      databaseHelper: _dbHelper,
      eventBus: _eventBus,
    );

    _groupService = GroupServiceImpl(
      connectionManager: _connectionManager,
      databaseHelper: _dbHelper,
      eventBus: _eventBus,
    );

    _conversationService = ConversationServiceImpl();
  }

  void _initUserStatusManager() {
    _userStatusManager?.dispose();
    _userStatusManager = UserStatusManager(
      connectionManager: _connectionManager,
      eventBus: _eventBus,
      currentUserId: currentUserId!,
    );
    _userStatusManager!.init();
  }

  void _setupEventHandlers() {
    _connectionSub = _connectionManager.onStatusChanged.listen((status) {
      switch (status) {
        case ConnectionStatus.connected:
          for (var listener in _connectionListeners) {
            listener.onConnected();
          }
          _eventBus.fire(ConnectionEvent(type: ConnectionEventType.connected));
          break;
        case ConnectionStatus.disconnected:
          for (var listener in _connectionListeners) {
            listener.onDisconnected();
          }
          _eventBus.fire(
            ConnectionEvent(type: ConnectionEventType.disconnected),
          );
          break;
        case ConnectionStatus.connecting:
          for (var listener in _connectionListeners) {
            listener.onConnecting();
          }
          _eventBus.fire(ConnectionEvent(type: ConnectionEventType.connecting));
          break;
        case ConnectionStatus.reconnecting:
          for (var listener in _connectionListeners) {
            listener.onReconnecting();
          }
          _eventBus.fire(
            ConnectionEvent(type: ConnectionEventType.reconnecting),
          );
          break;
      }
    });

    _messageSub = _connectionManager.onMessage.listen((data) {
      _handleIncomingMessage(data);
    });
  }

  Future<void> connect(String userToken) async {
    if (!_isInitialized) {
      throw StateError('IMClient未初始化，请先调用init()方法');
    }

    token = userToken;

    try {
      await _connectionManager.connect(serverUrl, token);

      if (currentUserId != null) {
        _initUserStatusManager();
        _initOfflineSync();
      }

      if (_reconnectManager == null) {
        _reconnectManager = ReconnectManager(
          onReconnect: () async {
            try {
              await _connectionManager.connect(serverUrl, token);
              return true;
            } catch (e) {
              return false;
            }
          },
          onReconnectSuccess: () {
            _userStatusManager?.resumeAfterReconnect();
            if (_offlineSync != null) {
              _offlineSync!.start();
              _offlineSync!.syncNow();
            }
          },
          onReconnectFailed: () {
            for (var listener in _connectionListeners) {
              listener.onReconnectFailed();
            }
          },
          onStatusChange: (_) {},
        );

        _reconnectSub = _connectionManager.onStatusChanged.listen((status) {
          if (status == ConnectionStatus.disconnected &&
              currentUserId != null) {
            _reconnectManager?.scheduleReconnect();
          }
        });
      }
    } catch (e) {
      throw Exception('连接失败: $e');
    }
  }

  Future<void> disconnect() async {
    _stopOfflineSync();
    _connectionManager.disconnect();
    token = '';
    currentUserId = null;
  }

  ConnectionStatus get connectionStatus => _connectionManager.status;

  bool get isConnected => _connectionManager.isConnected;

  Future<Message> sendMessage({
    required int toId,
    required String content,
    int msgType = 0,
  }) async {
    return _messageService.sendMessage(
      toId: toId,
      content: content,
      msgType: msgType,
    );
  }

  Future<Message> sendGroupMessage({
    required int groupId,
    required String content,
    int msgType = 0,
  }) async {
    return _messageService.sendGroupMessage(
      groupId: groupId,
      content: content,
      msgType: msgType,
    );
  }

  Future<List<Message>> getHistoryMessages({
    required int targetId,
    int page = 1,
    int size = 20,
  }) async {
    return _messageService.getHistoryMessages(
      targetId: targetId,
      page: page,
      size: size,
    );
  }

  Future<List<Message>> getGroupHistoryMessages({
    required int groupId,
    int page = 1,
    int size = 20,
  }) async {
    return _messageService.getHistoryMessages(
      targetId: 0,
      groupId: groupId,
      page: page,
      size: size,
    );
  }

  Future<void> recallMessage(int messageId) async {
    await _messageService.recallMessage(messageId);
  }

  Future<Message?> getMessage(int messageId) async {
    return _messageService.getMessage(messageId);
  }

  Future<List<Message>> getUnreadMessages(int userId) async {
    return _messageService.getUnreadMessages(userId);
  }

  Future<void> markAsRead(int messageId, {int? groupId}) async {
    await _messageService.markAsRead(messageId, groupId: groupId);
  }

  Future<void> markTargetAsRead({required int targetId, int? groupId}) async {
    await _messageService.markConversationAsRead(
      targetId: targetId,
      groupId: groupId,
    );
  }

  Future<List<Conversation>> getConversationList() async {
    if (currentUserId == null) return [];
    return _conversationService.getConversationList(currentUserId!);
  }

  Future<Conversation?> getConversation(int conversationId) async {
    return _conversationService.getConversation(conversationId);
  }

  Future<Conversation> getOrCreateConversation({
    required int targetType,
    required int targetId,
  }) async {
    if (currentUserId == null) {
      throw StateError('用户未登录，无法创建会话');
    }
    return _conversationService.getOrCreateConversation(
      userId: currentUserId!,
      targetType: targetType,
      targetId: targetId,
    );
  }

  Future<void> deleteConversation(int conversationId) async {
    await _conversationService.deleteConversation(conversationId);
  }

  Future<void> markConversationAsRead(int conversationId) async {
    await _conversationService.markConversationAsRead(conversationId);
  }

  Future<int> getTotalUnreadCount() async {
    if (currentUserId == null) return 0;
    return _conversationService.getTotalUnreadCount(currentUserId!);
  }

  Future<Group> createGroup({
    required String name,
    List<int>? memberIds,
  }) async {
    return _groupService.createGroup(name: name, memberIds: memberIds);
  }

  Future<Group> createGroupWithAvatar({
    required String name,
    String? avatar,
    List<int>? memberIds,
  }) async {
    return _groupService.createGroup(
      name: name,
      avatar: avatar,
      memberIds: memberIds,
    );
  }

  Future<void> dismissGroup(int groupId) async {
    await _groupService.dismissGroup(groupId);
  }

  Future<void> addGroupMembers({
    required int groupId,
    required List<int> userIds,
  }) async {
    await _groupService.addGroupMembers(groupId: groupId, userIds: userIds);
  }

  Future<void> removeGroupMember({
    required int groupId,
    required int userId,
  }) async {
    await _groupService.removeGroupMember(groupId: groupId, userId: userId);
  }

  Future<void> transferOwner({
    required int groupId,
    required int newOwnerId,
  }) async {
    await _groupService.transferOwner(groupId: groupId, newOwnerId: newOwnerId);
  }

  Future<Group> updateGroupInfo({
    required int groupId,
    String? name,
    String? avatar,
  }) async {
    return _groupService.updateGroupInfo(
      groupId: groupId,
      name: name,
      avatar: avatar,
    );
  }

  Future<Group> getGroup(int groupId) async {
    return _groupService.getGroup(groupId);
  }

  Future<List<Group>> getUserGroups({int? userId}) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) {
      throw StateError('用户未登录，无法获取群组列表');
    }
    return _groupService.getUserGroups(targetUserId);
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'message' || type == 'private_message') {
      final messageData = data['data'] as Map<String, dynamic>? ?? data;
      final message = Message.fromJson(messageData);

      _dbHelper.insertMessage(message);

      for (var listener in _messageListeners) {
        listener.onMessageReceived(message);
      }
      _eventBus.fire(MessageReceivedEvent(message: message));

      _updateConversationFromMessage(message);
    } else if (type == 'read_receipt') {
      _handleReadReceipt(data);
    } else if (type == 'recall_message') {
      _handleRecalledMessage(data);
    } else if (type == 'pong') {
    } else if (type == 'presence_update') {
      final userData = data['data'] as Map<String, dynamic>? ?? data;
      final user = User.fromJson(userData);
      _eventBus.fire(UserPresenceEvent(user: user));
    }
  }

  Future<void> _handleReadReceipt(Map<String, dynamic> data) async {
    try {
      final rawIds = data['messageIds'];
      List<int> messageIds;

      if (rawIds is List) {
        messageIds = rawIds
            .map((e) => e is int ? e : int.parse(e.toString()))
            .toList();
      } else {
        _log.w('read_receipt 格式错误，缺少 messageIds');
        return;
      }

      for (final msgId in messageIds) {
        await _dbHelper.updateMessageStatus(msgId, MessageStatus.read);
      }

      _eventBus.fire(MessagesReadEvent(messageIds: messageIds));
      _log.i('收到已读回执, messageIds=$messageIds');
    } catch (e) {
      _log.e('处理已读回执失败', error: e);
    }
  }

  Future<void> _handleRecalledMessage(Map<String, dynamic> data) async {
    try {
      final messageId = data['messageId'];
      if (messageId == null) {
        _log.w('recall_message 格式错误，缺少 messageId');
        return;
      }

      final msgId = messageId is int
          ? messageId
          : int.parse(messageId.toString());
      final existingMessage = await getMessage(msgId);

      if (existingMessage != null &&
          existingMessage.status != MessageStatus.recalled) {
        final recalledMessage = existingMessage.copyWith(
          status: MessageStatus.recalled,
          content: '[消息已撤回]',
        );

        final db = await _dbHelper.database;
        await db.update(
          'messages',
          {
            'content': recalledMessage.content,
            'status': recalledMessage.status.value,
          },
          where: 'id = ?',
          whereArgs: [msgId],
        );

        _eventBus.fire(MessageRecalledEvent(message: recalledMessage));
        _log.i('收到消息撤回通知, messageId=$msgId');
      }
    } catch (e) {
      _log.e('处理消息撤回通知失败', error: e);
    }
  }

  void addMessageListener(MessageListener listener) {
    if (!_messageListeners.contains(listener)) {
      _messageListeners.add(listener);
    }
  }

  void removeMessageListener(MessageListener listener) {
    _messageListeners.remove(listener);
  }

  void addConnectionListener(ConnectionListener listener) {
    if (!_connectionListeners.contains(listener)) {
      _connectionListeners.add(listener);
    }
  }

  void removeConnectionListener(ConnectionListener listener) {
    _connectionListeners.remove(listener);
  }

  Future<void> reset() async {
    await dispose();
    _instance = null;
    _isInitialized = false;
    serverUrl = '';
    token = '';
    currentUserId = null;
  }

  Future<void> dispose() async {
    _connectionSub?.cancel();
    _connectionSub = null;
    _messageSub?.cancel();
    _messageSub = null;
    _reconnectSub?.cancel();
    _reconnectSub = null;

    _messageService.dispose();
    _groupService.dispose();
    _userStatusManager?.dispose();
    _userStatusManager = null;
    _offlineSync?.dispose();
    _offlineSync = null;

    _reconnectManager = null;
    await disconnect();
    _connectionManager.dispose();
    _eventBus.dispose();
    await _dbHelper.close();

    _messageListeners.clear();
    _connectionListeners.clear();
    _isInitialized = false;
  }

  void _initOfflineSync() {
    if (_config.enableOfflineSync) {
      _offlineSync?.dispose();
      _offlineSync = OfflineMessageSync(
        client: this,
        dbHelper: _dbHelper,
        eventBus: _eventBus,
      );
      _offlineSync!.start();
      _log.i('离线消息同步已初始化，开始首次同步');
      _offlineSync!.syncNow();
    }
  }

  void _stopOfflineSync() {
    _offlineSync?.stop();
    _log.i('离线消息同步已停止');
  }

  Future<void> _updateConversationFromMessage(Message message) async {
    if (currentUserId == null) return;

    final isPrivate = message.groupId == null;
    final targetType = isPrivate ? 1 : 2;
    final targetId = isPrivate
        ? (message.fromId == currentUserId ? message.toId : message.fromId)
        : message.groupId!;

    try {
      final existingConversation = await _conversationService
          .getOrCreateConversation(
            userId: currentUserId!,
            targetType: targetType,
            targetId: targetId,
          );

      final updatedConversation = existingConversation.copyWith(
        lastMessage: message,
        updateTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: message.fromId != currentUserId
            ? existingConversation.unreadCount + 1
            : existingConversation.unreadCount,
      );

      if (existingConversation.id != null) {
        await _conversationService.updateLastMessage(
          existingConversation.id!,
          message,
        );

        if (message.fromId != currentUserId) {
          await _conversationService.incrementUnreadCount(
            existingConversation.id!,
            count: 1,
          );
        }
      }

      _eventBus.fire(
        ConversationUpdatedEvent(conversation: updatedConversation),
      );
    } catch (e) {
      _log.e('[IMClient] 更新会话失败', error: e);
    }
  }
}
