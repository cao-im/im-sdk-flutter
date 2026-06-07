import 'dart:async';

import '../core/connection_manager.dart';
import '../core/connection_status.dart';
import '../core/hybrid_message_sync.dart';
import '../core/reconnect.dart';
import '../core/token_manager.dart';
import '../event/event_bus.dart';
import '../event/event_listener.dart';
import '../event/im_event.dart';
import '../model/message.dart';
import '../model/conversation.dart';
import '../model/group.dart';
import '../model/user.dart';
import '../storage/storage_factory.dart';
import '../storage/storage_interface.dart';
import '../utils/logger.dart';
import '../service/message_service_impl.dart';
import '../service/conversation_service_impl.dart';
import '../service/group_service_impl.dart';
import '../core/read_receipt_manager.dart';

class IMConfig {
  final int heartbeatInterval;
  final int maxRetries;
  final int reconnectMaxRetries;
  final bool enableInfiniteReconnect;
  final int reconnectBaseDelayMs;
  final int reconnectMaxDelayMs;
  final DelayCalculator? customReconnectDelayCalculator;
  final int connectTimeoutSeconds;
  final bool enableOfflineSync;

  const IMConfig({
    this.heartbeatInterval = 30,
    this.maxRetries = 5,
    this.reconnectMaxRetries = 5,
    this.enableInfiniteReconnect = false,
    this.reconnectBaseDelayMs = 1000,
    this.reconnectMaxDelayMs = 30000,
    this.customReconnectDelayCalculator,
    this.connectTimeoutSeconds = 10,
    this.enableOfflineSync = true,
  });

  IMConfig copyWith({
    int? heartbeatInterval,
    int? maxRetries,
    int? reconnectMaxRetries,
    bool? enableInfiniteReconnect,
    int? reconnectBaseDelayMs,
    int? reconnectMaxDelayMs,
    DelayCalculator? customReconnectDelayCalculator,
    int? connectTimeoutSeconds,
    bool? enableOfflineSync,
  }) {
    return IMConfig(
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      maxRetries: maxRetries ?? this.maxRetries,
      reconnectMaxRetries: reconnectMaxRetries ?? this.reconnectMaxRetries,
      enableInfiniteReconnect:
          enableInfiniteReconnect ?? this.enableInfiniteReconnect,
      reconnectBaseDelayMs: reconnectBaseDelayMs ?? this.reconnectBaseDelayMs,
      reconnectMaxDelayMs: reconnectMaxDelayMs ?? this.reconnectMaxDelayMs,
      customReconnectDelayCalculator:
          customReconnectDelayCalculator ?? this.customReconnectDelayCalculator,
      connectTimeoutSeconds:
          connectTimeoutSeconds ?? this.connectTimeoutSeconds,
      enableOfflineSync: enableOfflineSync ?? this.enableOfflineSync,
    );
  }
}

class IMClient {
  static const int _defaultPort = 8080;

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
  bool _dbAvailable = true;
  late IMConfig _config;

  late ConnectionManager _connectionManager;
  late EventBus _eventBus;
  late TokenManager _tokenManager;
  StorageInterface _storage = _FallbackStorage();

  late MessageServiceImpl _messageService;
  late ConversationServiceImpl _conversationService;
  late GroupServiceImpl _groupService;
  HybridMessageSync? _hybridSync;

  /// 已读回执管理器（支持断网缓存+重连补发）
  ReadReceiptManager? _readReceiptManager;

  final List<MessageListener> _messageListeners = [];
  final List<ConnectionListener> _connectionListeners = [];
  final List<FriendRequestListener> _friendRequestListeners = [];

  StreamSubscription? _connectionSub;
  StreamSubscription? _messageSub;
  StreamSubscription? _reconnectSub;
  ReconnectManager? _reconnectManager;

  MessageServiceImpl get messageService => _messageService;
  ConversationServiceImpl get conversationService => _conversationService;
  GroupServiceImpl get groupService => _groupService;
  EventBus get eventBus => _eventBus;
  StorageInterface get storage => _storage;
  ConnectionManager get connectionManager => _connectionManager;
  IMConfig get config => _config;
  List<MessageListener> get messageListeners =>
      List.unmodifiable(_messageListeners);

  HybridMessageSync? get hybridSync => _hybridSync;

  Future<void> syncOfflineMessages() async {
    await _hybridSync?.syncNow();
  }

  SyncMode getCurrentSyncMode() {
    return _hybridSync?.currentMode ?? SyncMode.realtime;
  }

  Map<String, dynamic> getSyncDebugInfo() {
    return _hybridSync?.getDebugInfo() ?? {};
  }

  Future<void> init({required String serverUrl, IMConfig? config}) async {
    print('📍[IMClient] init()开始, serverUrl: $serverUrl');

    if (_isInitialized) {
      print('⚠️[IMClient] 已初始化，跳过');
      return;
    }

    _config = config ?? _defaultConfig;

    final uri = Uri.parse(serverUrl);
    print('📍[IMClient] 解析URI: scheme=${uri.scheme}, host=${uri.host}, port=${uri.port}, path=${uri.path}');

    // 端口可自由配置，不再强制限制
    int resolvedPort = uri.hasPort ? uri.port : _defaultPort;
    if (!uri.hasPort) {
      print('💡[IMClient] 未指定端口，使用默认端口: $_defaultPort');
    } else {
      print('✅[IMClient] 使用指定端口: $resolvedPort');
    }

    this.serverUrl = uri.replace(port: resolvedPort).toString();
    print('📍[IMClient] 最终serverUrl: $this.serverUrl');

    print('📍[IMClient] 创建并初始化 TokenManager...');
    _tokenManager = TokenManager();
    _tokenManager.init(serverUrl: this.serverUrl);
    print('📍[IMClient] 创建 ConnectionManager...');
    _connectionManager = ConnectionManager();
    print('📍[IMClient] 创建 EventBus...');
    _eventBus = EventBus();
    print('📍[IMClient] 初始化存储 (自动检测平台)...');
    try {
      _storage = await StorageFactory.getInstance(userId: currentUserId);
      print('✅[IMClient] 存储初始化完成');
    } catch (e, stack) {
      print('⚠️[IMClient] 存储初始化失败(非致命): $e, SDK将以无持久化模式运行');
      _dbAvailable = false;
    }

    print('📍[IMClient] 初始化服务 (Message/Group/Conversation)...');
    _initServices();
    print('✅[IMClient] 服务初始化完成');

    print('📍[IMClient] 设置事件处理器...');
    _setupEventHandlers();
    print('✅[IMClient] 事件处理器设置完成');

    _isInitialized = true;
    print('✅[IMClient] ====== init() 完成, isInitialized=true ======');
  }

  void _initServices() {
    _messageService = MessageServiceImpl(
      connectionManager: _connectionManager,
      databaseHelper: _storage,
      eventBus: _eventBus,
    );

    _groupService = GroupServiceImpl(
      connectionManager: _connectionManager,
      databaseHelper: _storage,
      eventBus: _eventBus,
    );

    _conversationService = ConversationServiceImpl(
      dbHelper: _storage,
      onSendReadReceipt: ({required int targetId, int? groupId}) async {
        // 委托给 MessageService 处理：查询未读消息 + 通过 ReadReceiptManager 发送回执
        await _messageService.markConversationAsRead(
          targetId: targetId,
          groupId: groupId,
        );
      },
    );
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

  Future<void> connect(String userToken, {int? userId, String? refreshToken}) async {
    print('📍[IMClient] connect()开始, isInitialized: $_isInitialized');

    if (!_isInitialized) {
      print('❌[IMClient] 未初始化，抛出异常');
      throw StateError('IMClient未初始化，请先调用init()方法');
    }

    print('📍[IMClient] 设置Token到TokenManager...');
    _tokenManager.setTokens(
      accessToken: userToken,
      refreshToken: refreshToken,
    );

    print('📍[IMClient] 连接前检查Token有效性...');
    await _tokenManager.ensureValidTokenBeforeConnect();

    token = _tokenManager.accessToken ?? userToken;
    if (userId != null && userId > 0) {
      currentUserId = userId;
    }
    print('📍[IMClient] token已设置, serverUrl: $serverUrl, currentUserId: $currentUserId');

    if (currentUserId != null) {
      print('📍[IMClient] 🔄 切换用户数据库 (userId=$currentUserId)...');
      try {
        _storage = await StorageFactory.getInstance(userId: currentUserId);
        print('✅[IMClient] 用户数据库切换完成, 存储类型: ${_storage.runtimeType}');

        print('📍[IMClient] 🔄 重新初始化服务 (更新存储引用)...');
        _initServices();
        print('✅[IMClient] 服务重新初始化完成');
      } catch (e) {
        print('⚠️[IMClient] 用户数据库切换失败 (非致命): $e');
      }
    }

    // 📝 初始化已读回执管理器（支持断网缓存+重连补发）
    _initReadReceiptManager();

    try {
      print('📍[IMClient] ConnectionManager.connect(serverUrl, token)...');
      await _connectionManager.connect(serverUrl, token);
      print('✅[IMClient] ConnectionManager.connect() 返回成功');

      if (currentUserId != null) {
        print('📍[IMClient] 初始化 HybridSync (微信模式)...');
        _initHybridSync();
        print('✅[IMClient] HybridSync 初始化完成');
      } else {
        print('⚠️[IMClient] currentUserId 为空，跳过 HybridSync');
      }

      if (_reconnectManager == null) {
        print('📍[IMClient] 初始化 ReconnectManager...');
        _reconnectManager = ReconnectManager(
          maxRetries: _config.maxRetries,
          infiniteRetry: _config.enableInfiniteReconnect,
          baseDelayMs: _config.reconnectBaseDelayMs,
          maxDelayMs: _config.reconnectMaxDelayMs,
          delayCalculator: _config.customReconnectDelayCalculator,
          onReconnect: () async {
            try {
              print('🔄[IMClient] ReconnectManager执行重连回调, 重连前token长度: ${token.length}');
              // 🔑 重连前先检查并刷新 Token（修复：避免使用已过期的旧 Token）
              await _tokenManager.ensureValidTokenBeforeConnect();
              token = _tokenManager.accessToken ?? token;
              print('🔄[IMClient] 刷新后 token 长度: ${token.length} (若长度变化说明Token已刷新)');
              await _connectionManager.connect(serverUrl, token);
              return true;
            } catch (e) {
              print('❌[IMClient] ReconnectManager 重连异常: $e');
              return false;
            }
          },
          onReconnectSuccess: () {
            print('✅[IMClient] ReconnectManager 重连成功回调');
            if (_hybridSync != null) {
              _hybridSync!.start();
              _hybridSync!.syncNow();
            }
            // 🔄 重连成功后自动补发缓存的已读回执
            _readReceiptManager?.flushPendingReceipts();
          },
          onReconnectFailed: () {
            print('❌[IMClient] ReconnectManager 重连失败回调 (已达最大次数)');
            for (var listener in _connectionListeners) {
              listener.onReconnectFailed();
            }
          },
          onStatusChange: (isReconnecting) {
            for (var listener in _connectionListeners) {
              listener.onReconnectingStateChanged(isReconnecting);
            }
          },
          onReconnectAttempt: (info) {
            print('🔄[IMClient] 重连尝试: $info');
          },
        );
        print('✅[IMClient] ReconnectManager初始化完成, 最大重试:${_config.maxRetries}次, 无限重试:${_config.enableInfiniteReconnect}, 基础延迟:${_config.reconnectBaseDelayMs}ms, 最大延迟:${_config.reconnectMaxDelayMs}ms');

        _reconnectSub = _connectionManager.onStatusChanged.listen((status) {
          print('🔗[IMClient] 连接状态变更: $status');
          
          if (status == ConnectionStatus.disconnected && currentUserId != null) {
            final reason = '连接状态变为 disconnected';
            print('📢[IMClient] 触发自动重连, 原因: $reason');
            _reconnectManager?.scheduleReconnect(reason: reason);
          }
        });
      } else {
        print('ℹ️[IMClient] ReconnectManager 已存在，跳过初始化');
      }
    } catch (e) {
      throw Exception('连接失败: $e');
    }
  }

  Future<void> disconnect() async {
    _stopHybridSync();
    _reconnectManager?.cancel();
    _connectionManager.disconnect();

    // 🗑️ 清理回执管理器
    _readReceiptManager?.dispose();
    _readReceiptManager = null;

    token = '';
    currentUserId = null;

    StorageFactory.reset();
  }

  ConnectionStatus get connectionStatus => _connectionManager.status;

  bool get isConnected => _connectionManager.isConnected;

  bool get isReconnecting => _reconnectManager?.isReconnecting ?? false;

  int get reconnectRetryCount => _reconnectManager?.retryCount ?? 0;

  String get reconnectStatusDescription =>
      _reconnectManager?.statusDescription ?? '未初始化';

  Future<bool> manualReconnect({String? reason}) async {
    if (!_isInitialized) {
      throw StateError('IMClient 未初始化，请先调用 init()');
    }

    if (token.isEmpty) {
      throw StateError('Token 为空，请先调用 connect()');
    }

    print('🔄[IMClient] 手动触发重连${reason != null ? ', 原因: $reason' : ''}');

    try {
      _reconnectManager?.cancel();
      _reconnectManager?.reset(logReset: false);

      print('🔄[IMClient] 执行连接...');
      // 🔑 手动重连前也先检查并刷新 Token
      await _tokenManager.ensureValidTokenBeforeConnect();
      token = _tokenManager.accessToken ?? token;
      await _connectionManager.connect(serverUrl, token);

      print('✅[IMClient] 手动重连成功');
      if (currentUserId != null) {
        if (_hybridSync != null) {
          _hybridSync!.start();
          _hybridSync!.syncNow();
        }
      }
      return true;
    } catch (e) {
      print('❌[IMClient] 手动重连失败: $e');

      if (_reconnectManager != null && currentUserId != null) {
        _reconnectManager!.scheduleReconnect(reason: reason ?? '手动重连失败');
      }
      return false;
    }
  }

  void cancelReconnect() {
    _reconnectManager?.cancel();
    print('🛑[IMClient] 已取消自动重连');
  }

  Map<String, dynamic> getReconnectDebugInfo() {
    final managerInfo = _reconnectManager?.getDebugInfo() ?? {};
    return {
      ...managerInfo,
      'hasReconnectManager': _reconnectManager != null,
      'isInitialized': _isInitialized,
      'hasToken': token.isNotEmpty,
      'currentUserId': currentUserId,
    };
  }

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
    print('📍[IMClient] 🔍 getConversationList 被调用, currentUserId=$currentUserId');

    // ✅ 如果 currentUserId 为 null，尝试获取所有会话（用于未登录状态）
    if (currentUserId == null) {
      print('📍[IMClient] ⚠️ currentUserId 为空，尝试获取所有会话');
      
      // 检查 _storage 是否已初始化
      try {
        final testCount = await _storage.getUnreadCount(0);
        print('📍[IMClient] ✅ _storage 已正常工作');
      } catch (e) {
        print('📍[IMClient] ❌ _storage 未初始化或出错: $e');
        // 尝试重新初始化
        try {
          _storage = await StorageFactory.getInstance(userId: currentUserId);
          print('📍[IMClient] 🔄 _storage 重新初始化成功');
        } catch (e2) {
          print('📍[IMClient] ❌ _storage 重新初始化也失败: $e2');
          return [];
        }
      }

      // 尝试从存储中获取所有会话（不按 userId 过滤）
      try {
        final allConversations = await _storage.getConversations(0);
        print('📍[IMClient] 📋 从存储获取到 ${allConversations.length} 个会话');
        
        if (allConversations.isNotEmpty) {
          for (final conv in allConversations) {
            print('📍[IMClient]   - 会话: id=${conv.id}, targetId=${conv.targetId}, type=${conv.targetType.name}');
          }
        }
        
        return allConversations;
      } catch (e) {
        print('📍[IMClient] ❌ 获取会话失败: $e');
        return [];
      }
    }
    
    // 正常流程：使用 conversationService
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
    _log.i('📡 [IMClient._handleIncomingMessage] 收到服务端消息, type=$type, data=$data');

    if (type == 'message' || type == 'private_message') {
      final messageData = data['data'] as Map<String, dynamic>? ?? data;
      _log.i('📡 [IMClient] 解析消息数据: $messageData');
      final message = Message.fromJson(messageData);

      // ✅ 先保存到本地存储（确保数据持久化）
      _storage.insertMessage(message).then((_) {
        // 保存成功后，再触发事件和更新会话
        for (var listener in _messageListeners) {
          listener.onMessageReceived(message);
        }
        _eventBus.fire(MessageReceivedEvent(message: message));
        _updateConversationFromMessage(message);
      }).catchError((e) {
        _log.e('[IMClient] 保存收到的消息失败', error: e);
        // 即使保存失败，也要通知 UI 和更新会话
        for (var listener in _messageListeners) {
          listener.onMessageReceived(message);
        }
        _eventBus.fire(MessageReceivedEvent(message: message));
        _updateConversationFromMessage(message);
      });
    } else if (type == 'read_receipt') {
      _handleReadReceipt(data);
    } else if (type == 'send_confirmation') {
      _handleSendConfirmation(data);
    } else if (type == 'recall_message') {
      _handleRecalledMessage(data);
    } else if (type == 'pong') {
    } else if (type == 'friend_request') {
      _handleFriendRequest(data);
    } else if (type == 'friend_accepted') {
      _handleFriendAccepted(data);
    } else if (type == 'friend_rejected') {
      _handleFriendRejected(data);
    } else if (type == 'offline_messages') {
      _handleOfflineMessages(data);
    }
  }

  void _handleOfflineMessages(Map<String, dynamic> data) {
    try {
      final messages = data['messages'];

      if (messages is List) {
        final messagesList = messages
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .toList();

        _log.i('📥 收到离线消息响应: 共 ${messagesList.length} 条消息');

        _eventBus.fire(OfflineMessagesEvent(messages: messagesList));
      } else {
        _log.w('⚠️ 离线消息格式错误: messages字段不是数组');
        _eventBus.fire(OfflineMessagesEvent(messages: []));
      }
    } catch (e) {
      _log.e('❌ 处理离线消息响应失败', error: e);
      _eventBus.fire(OfflineMessagesEvent(messages: []));
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
        await _storage.updateMessageStatus(msgId, MessageStatus.read);
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

        await _storage.updateMessageContent(msgId, '[消息已撤回]', MessageStatus.recalled);

        _eventBus.fire(MessageRecalledEvent(message: recalledMessage));
        _log.i('收到消息撤回通知, messageId=$msgId');
      }
    } catch (e) {
      _log.e('处理消息撤回通知失败', error: e);
    }
  }

  /// 处理服务端发送确认：用 mid 匹配本地消息，更新状态为已送达/已发送
  void _handleSendConfirmation(Map<String, dynamic> data) {
    try {
      final mid = data['mid'] ?? data['messageId'];
      final serverId = data['id'];
      final statusStr = data['status'] ?? 'sent';
      _log.i('📤 [IMClient] 收到 send_confirmation, mid=$mid, serverId=$serverId, status=$statusStr');

      if (mid == null) return;

      // 用 mid 查找本地消息并更新
      _storage.getMessageByMid(mid).then((localMessage) async {
        if (localMessage == null) {
          _log.w('⚠️ [IMClient] 未找到 mid=$mid 对应的本地消息');
          return;
        }

        // 更新消息状态
        MessageStatus newStatus;
        switch (statusStr) {
          case 'delivered':
            newStatus = MessageStatus.delivered;
          case 'read':
            newStatus = MessageStatus.read;
          case 'failed':
            newStatus = MessageStatus.failed;
          default:
            newStatus = MessageStatus.sent;
        }

        // 更新本地记录：状态 + 服务端ID
        final updatedMessage = localMessage.copyWith(
          id: serverId ?? localMessage.id,
          status: newStatus,
        );
        await _storage.updateMessage(updatedMessage);

        _log.i('✅ [IMClient] 消息确认更新成功: mid=$mid, status=${newStatus.name}');
        _eventBus.fire(MessageSentEvent(message: updatedMessage));
      }).catchError((e) {
        _log.e('❌ [IMClient] 处理 send_confirmation 失败', error: e);
      });
    } catch (e) {
      _log.e('处理发送确认失败', error: e);
    }
  }

  void _handleFriendRequest(Map<String, dynamic> data) {
    try {
      final requestData = data['data'] as Map<String, dynamic>? ?? data;
      final fromId = requestData['fromId'] is int
          ? requestData['fromId']
          : int.parse(requestData['fromId'].toString());
      final toId = requestData['toId'] is int
          ? requestData['toId']
          : int.parse(requestData['toId'].toString());

      _log.i('收到好友请求通知: fromId=$fromId, toId=$toId');

      for (var listener in _friendRequestListeners) {
        listener.onFriendRequestReceived(fromId, toId);
      }

      _eventBus.fire(FriendRequestEvent(fromId: fromId, toId: toId));
    } catch (e) {
      _log.e('处理好友请求通知失败', error: e);
    }
  }

  Future<void> _handleFriendAccepted(Map<String, dynamic> data) async {
    try {
      final requestData = data['data'] as Map<String, dynamic>? ?? data;
      final fromId = requestData['fromId'] is int
          ? requestData['fromId']
          : int.parse(requestData['fromId'].toString());
      final toId = requestData['toId'] is int
          ? requestData['toId']
          : int.parse(requestData['toId'].toString());

      _log.i('收到好友接受通知: fromId=$fromId (同意者), toId=$toId (你)');

      for (var listener in _friendRequestListeners) {
        listener.onFriendAccepted(fromId, toId);
      }

      _eventBus.fire(FriendAcceptedEvent(fromId: fromId, toId: toId));

      await _createFriendConversationAndSystemMessage(fromId, toId, 'accepted');
    } catch (e) {
      _log.e('处理好友接受通知失败', error: e);
    }
  }

  void _handleFriendRejected(Map<String, dynamic> data) {
    try {
      final requestData = data['data'] as Map<String, dynamic>? ?? data;
      final fromId = requestData['fromId'] is int
          ? requestData['fromId']
          : int.parse(requestData['fromId'].toString());
      final toId = requestData['toId'] is int
          ? requestData['toId']
          : int.parse(requestData['toId'].toString());

      _log.i('收到好友拒绝通知: fromId=$fromId (拒绝者), toId=$toId (你)');

      for (var listener in _friendRequestListeners) {
        listener.onFriendRejected(fromId, toId);
      }

      _eventBus.fire(FriendRejectedEvent(fromId: fromId, toId: toId));
    } catch (e) {
      _log.e('处理好友拒绝通知失败', error: e);
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

  void addFriendRequestListener(FriendRequestListener listener) {
    if (!_friendRequestListeners.contains(listener)) {
      _friendRequestListeners.add(listener);
    }
  }

  void removeFriendRequestListener(FriendRequestListener listener) {
    _friendRequestListeners.remove(listener);
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
    _hybridSync?.dispose();
    _hybridSync = null;

    // 🗑️ 清理回执管理器
    _readReceiptManager?.dispose();
    _readReceiptManager = null;

    _reconnectManager = null;
    await disconnect();
    _connectionManager.dispose();
    _eventBus.dispose();
    await _storage.close();

    _messageListeners.clear();
    _connectionListeners.clear();
    _friendRequestListeners.clear();
    _isInitialized = false;
  }

  void _initHybridSync() {
    if (_config.enableOfflineSync) {
      _hybridSync?.dispose();
      _hybridSync = HybridMessageSync(
        client: this,
        dbHelper: _storage,
        eventBus: _eventBus,
      );
      _hybridSync!.start();
      _log.i('🚀 混合消息同步已初始化（微信模式），开始首次离线补拉');
      _hybridSync!.syncNow();
    }
  }

  /// 📝 初始化已读回执管理器（支持断网缓存+重连补发）
  void _initReadReceiptManager() {
    _readReceiptManager?.dispose(); // 先清理旧的

    _readReceiptManager = ReadReceiptManager(
      connectionManager: _connectionManager,
      batchDelay: const Duration(milliseconds: 500), // 默认500ms防抖
      onReconnected: () {
        _log.i('📝 已读回执补发完成，通知外部');
      },
    );

    _log.i('✅ ReadReceiptManager 已初始化（支持断网缓存+重连补发）');
  }

  // ==================== Token管理API ====================

  void setTokens({
    required String accessToken,
    String? refreshToken,
  }) {
    _tokenManager.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    token = _tokenManager.accessToken ?? accessToken;
  }

  Future<bool> refreshToken() async {
    return _tokenManager.refresh();
  }

  bool get isTokenExpiringSoon => _tokenManager.isTokenExpiringSoon();

  Map<String, dynamic> getTokenDebugInfo() {
    return _tokenManager.getDebugInfo();
  }

  // ==================== 公开API ====================

  /// 📝 发送已读回执（通过ReadReceiptManager，支持断网缓存）
  Future<void> sendReadReceipt(int messageId, {int? groupId}) async {
    await _readReceiptManager?.enqueueReceipt(messageId, groupId: groupId);
  }

  /// 📝 批量发送已读回执
  Future<void> sendReadReceiptBatch(List<int> messageIds) async {
    await _readReceiptManager?.enqueueBatch(messageIds);
  }

  /// 📝 获取当前缓存的待发送回执数量
  int get pendingReceiptCount => _readReceiptManager?.pendingCount ?? 0;

  /// 📊 获取回执管理器调试信息
  Map<String, dynamic> getReceiptDebugInfo() {
    return _readReceiptManager?.getDebugInfo() ?? {'status': '未初始化'};
  }

  void _stopHybridSync() {
    _hybridSync?.stop();
    _log.i('混合消息同步已停止');
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

  Future<void> _createFriendConversationAndSystemMessage(
      int friendId, int myId, String status) async {
    if (currentUserId == null) {
      _log.e('❌ 创建好友会话失败: currentUserId 为空');
      return;
    }

    try {
      _log.i('🔍 开始创建好友会话: friendId=$friendId, myId=$myId, currentUserId=$currentUserId, 存储类型:${_storage.runtimeType}');

      final conversation = await _conversationService.getOrCreateConversation(
        userId: currentUserId!,
        targetType: 1,
        targetId: friendId,
      );

      _log.i('✅ 会话创建/获取成功: conversationId=${conversation.id}, targetType=${conversation.targetType}, targetId=${conversation.targetId}');

      final systemContent = status == 'accepted'
          ? '你们已成为好友，可以开始聊天了'
          : '好友请求已被拒绝';

      final systemMessage = Message(
        fromId: friendId,
        toId: currentUserId!,
        content: systemContent,
        msgType: MessageType.text,
        status: MessageStatus.read,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      _log.i('📝 准备插入系统消息: fromId=${systemMessage.fromId}, toId=${systemMessage.toId}, msgType=${systemMessage.msgType.value}');

      final messageId = await _storage.insertMessage(systemMessage);
      _log.i('✅ 消息插入成功: messageId=$messageId');

      final updatedConversation = conversation.copyWith(
        lastMessage: systemMessage,
        updateTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: status == 'accepted' ? conversation.unreadCount + 1 : conversation.unreadCount,
      );

      if (conversation.id != null) {
        _log.i('🔄 更新会话最后消息: conversationId=${conversation.id}');
        await _conversationService.updateLastMessage(conversation.id!, systemMessage);

        if (status == 'accepted') {
          await _conversationService.incrementUnreadCount(
            conversation.id!,
            count: 1,
          );
          _log.i('✅ 未读数+1');
        }
      } else {
        _log.w('⚠️ 会话ID为空，跳过更新操作');
      }

      for (final listener in _messageListeners) {
        listener.onMessageReceived(systemMessage);
      }
      _eventBus.fire(MessageReceivedEvent(message: systemMessage));
      _eventBus.fire(ConversationUpdatedEvent(conversation: updatedConversation));

      _log.i('✅ 已创建好友会话并插入系统消息: friendId=$friendId, content=$systemContent');
    } catch (e, stackTrace) {
      _log.e('[IMClient] 创建好友会话失败: $stackTrace', error: e);
    }
  }
}

/// ✅ 空实现的回退存储（当真实存储初始化失败时使用）
class _FallbackStorage implements StorageInterface {
  @override
  Future<void> init({int? userId}) async {}

  @override
  Future<int> insertMessage(Message message) async => 0;

  @override
  Future<List<Message>> getMessages({
    required int targetId,
    int? groupId,
    int? currentUserId,
    int page = 1,
    int size = 20,
  }) async => [];

  @override
  Future<Message?> getLastMessage(int targetId, {int? groupId}) async => null;

  @override
  Future<Message?> getMessageById(int messageId) async => null;

  @override
  Future<Message?> getMessageByMid(int mid) async => null;

  @override
  Future<void> updateMessageStatus(int messageId, MessageStatus status) async {}

  @override
  Future<void> updateMessage(Message message) async {}

  @override
  Future<void> updateMessageContent(int messageId, String content, MessageStatus status) async {}

  @override
  Future<int> getUnreadCount(int userId) async => 0;

  @override
  Future<void> markAsRead(int userId, {int? targetId, int? groupId}) async {}

  @override
  Future<int> insertConversation(Conversation conversation) async => 0;

  @override
  Future<List<Conversation>> getConversations(int userId) async => [];

  @override
  Future<void> updateConversation(Conversation conversation) async {}

  @override
  Future<void> updateUnreadCount(int conversationId, int count) async {}

  @override
  Future<void> deleteConversation(int conversationId) async {}

  @override
  Future<void> close() async {}
}
