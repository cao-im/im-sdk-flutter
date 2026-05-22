import 'dart:async';
import 'dart:collection';

import '../core/connection_manager.dart';
import '../event/event_bus.dart';
import '../event/im_event.dart';
import '../model/message.dart';
import '../storage/database_helper.dart';
import '../utils/logger.dart';
import 'message_service.dart';

class MessageServiceImpl implements MessageService {
  final ConnectionManager _connectionManager;
  final DatabaseHelper _databaseHelper;
  final EventBus _eventBus;

  static const int _maxRetryCount = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const int _maxQueueSize = 100;
  static const Duration _batchSendDelay = Duration(milliseconds: 500);

  final Queue<_PendingMessage> _messageQueue = Queue<_PendingMessage>();
  final Set<String> _sentMessageIds = {};
  Timer? _retryTimer;
  bool _isProcessing = false;

  late final ReadReceiptManager _readReceiptManager;

  final Logger _log = AppLogger.instance;

  MessageServiceImpl({
    required ConnectionManager connectionManager,
    required DatabaseHelper databaseHelper,
    required EventBus eventBus,
  }) : _connectionManager = connectionManager,
       _databaseHelper = databaseHelper,
       _eventBus = eventBus {
    _readReceiptManager = ReadReceiptManager(
      connectionManager: _connectionManager,
      batchDelay: _batchSendDelay,
    );
    _startQueueProcessor();
    _listenConnectionStatus();
  }

  void _listenConnectionStatus() {
    _connectionManager.onStatusChanged.listen((status) {
      if (status.name == 'connected') {
        _log.i('连接已恢复，开始处理消息队列');
        _processQueue();
      }
    });
  }

  @override
  Future<Message> sendMessage({
    required int toId,
    required String content,
    int msgType = 0,
    int? groupId,
  }) async {
    _log.i('准备发送私聊消息, toId=$toId, msgType=$msgType');

    if (content.isEmpty) {
      _log.e('消息内容不能为空');
      throw ArgumentError('消息内容不能为空');
    }

    final messageType = MessageType.fromValue(msgType);

    if (!_isValidMessageType(messageType)) {
      _log.e('不支持的消息类型: $msgType');
      throw ArgumentError('不支持的消息类型: $msgType');
    }

    final message = Message(
      fromId: _getCurrentUserId(),
      toId: toId,
      groupId: groupId,
      content: content,
      msgType: messageType,
      status: MessageStatus.sending,
    );

    final messageId = await _saveMessageToLocal(message);
    final savedMessage = message.copyWith(id: messageId);

    final dedupKey = _generateDedupKey(savedMessage);
    if (_isDuplicate(dedupKey)) {
      _log.w('检测到重复消息，跳过发送: $dedupKey');
      return savedMessage;
    }

    _addToQueue(
      _PendingMessage(message: savedMessage, isGroup: false, retryCount: 0),
    );

    return savedMessage;
  }

  @override
  Future<Message> sendGroupMessage({
    required int groupId,
    required String content,
    int msgType = 0,
  }) async {
    _log.i('准备发送群聊消息, groupId=$groupId, msgType=$msgType');

    if (groupId <= 0) {
      _log.e('群组ID无效: $groupId');
      throw ArgumentError('群组ID必须大于0');
    }

    if (content.isEmpty) {
      _log.e('消息内容不能为空');
      throw ArgumentError('消息内容不能为空');
    }

    final messageType = MessageType.fromValue(msgType);
    if (!_isValidMessageType(messageType)) {
      _log.e('不支持的消息类型: $msgType');
      throw ArgumentError('不支持的消息类型: $msgType');
    }

    final message = Message(
      fromId: _getCurrentUserId(),
      toId: 0,
      groupId: groupId,
      content: content,
      msgType: messageType,
      status: MessageStatus.sending,
    );

    final messageId = await _saveMessageToLocal(message);
    final savedMessage = message.copyWith(id: messageId);

    final dedupKey = _generateDedupKey(savedMessage);
    if (_isDuplicate(dedupKey)) {
      _log.w('检测到重复消息，跳过发送: $dedupKey');
      return savedMessage;
    }

    _addToQueue(
      _PendingMessage(message: savedMessage, isGroup: true, retryCount: 0),
    );

    return savedMessage;
  }

  @override
  Future<void> recallMessage(int messageId) async {
    _log.i('执行消息撤回, messageId=$messageId');

    final message = await getMessage(messageId);
    if (message == null) {
      _log.e('消息不存在: $messageId');
      throw StateError('消息不存在: $messageId');
    }

    final currentUserId = _getCurrentUserId();
    if (message.fromId != currentUserId) {
      _log.e(
        '无权撤回他人消息, messageId=$messageId, fromId=${message.fromId}, currentUserId=$currentUserId',
      );
      throw StateError('只能撤回自己发送的消息');
    }

    if (message.status == MessageStatus.failed) {
      _log.w('无法撤回已失败的消息: $messageId');
      throw StateError('无法撤回已失败的消息');
    }

    if (message.status == MessageStatus.recalled) {
      _log.w('消息已被撤回，无法重复撤回: $messageId');
      throw StateError('消息已被撤回');
    }

    if (message.status == MessageStatus.sending) {
      _log.w('消息正在发送中，无法撤回: $messageId');
      throw StateError('消息正在发送中，请稍后再试');
    }

    final recallWindowMs = 120000;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - message.timestamp > recallWindowMs) {
      _log.e('消息已超过撤回时间窗口(2分钟), messageId=$messageId');
      throw StateError('超过2分钟无法撤回');
    }

    try {
      if (!_connectionManager.isConnected) {
        _log.e('网络未连接，无法撤回消息');
        throw StateError('网络未连接，请检查网络后重试');
      }

      _connectionManager.sendMessage({
        'type': 'recall_message',
        'messageId': messageId,
        'timestamp': now,
      });

      final recalledMessage = message.copyWith(
        status: MessageStatus.recalled,
        content: '[消息已撤回]',
      );
      await _updateMessageInDb(recalledMessage);

      _eventBus.fire(MessageRecalledEvent(message: recalledMessage));
      _log.i('消息撤回成功, messageId=$messageId');
    } catch (e) {
      _log.e('消息撤回失败', error: e);
      rethrow;
    }
  }

  @override
  Future<List<Message>> getHistoryMessages({
    required int targetId,
    int? groupId,
    int page = 1,
    int size = 20,
  }) async {
    _log.i(
      '查询历史消息, targetId=$targetId, groupId=$groupId, page=$page, size=$size',
    );

    if (page < 1) {
      _log.e('页码必须大于等于1');
      throw ArgumentError('页码必须大于等于1');
    }

    if (size < 1 || size > 100) {
      _log.e('每页大小必须在1-100之间');
      throw ArgumentError('每页大小必须在1-100之间');
    }

    try {
      final messages = await _databaseHelper.getMessages(
        targetId: targetId,
        groupId: groupId,
        page: page,
        size: size,
      );
      _log.i('查询到 ${messages.length} 条历史消息');
      return messages;
    } catch (e) {
      _log.e('查询历史消息失败', error: e);
      rethrow;
    }
  }

  @override
  Future<Message?> getMessage(int messageId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'messages',
        where: 'id = ?',
        whereArgs: [messageId],
        limit: 1,
      );

      if (maps.isEmpty) {
        _log.d('未找到消息: $messageId');
        return null;
      }

      final map = maps.first;
      final message = Message.fromJson({
        'id': map['id'],
        'fromId': map['from_id'],
        'toId': map['to_id'],
        'groupId': map['group_id'],
        'content': map['content'],
        'msgType': map['msg_type'],
        'status': map['status'],
        'timestamp': map['timestamp'],
        'localPath': map['local_path'],
      });

      return message;
    } catch (e) {
      _log.e('获取消息失败, messageId=$messageId', error: e);
      return null;
    }
  }

  @override
  Future<List<Message>> getUnreadMessages(int userId) async {
    _log.i('获取未读消息, userId=$userId');

    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'messages',
        where: 'to_id = ? AND status < ?',
        whereArgs: [userId, MessageStatus.read.value],
        orderBy: 'timestamp ASC',
      );

      final messages = maps
          .map(
            (map) => Message.fromJson({
              'id': map['id'],
              'fromId': map['from_id'],
              'toId': map['to_id'],
              'groupId': map['group_id'],
              'content': map['content'],
              'msgType': map['msg_type'],
              'status': map['status'],
              'timestamp': map['timestamp'],
              'localPath': map['local_path'],
            }),
          )
          .toList();

      _log.i('获取到 ${messages.length} 条未读消息');
      return messages;
    } catch (e) {
      _log.e('获取未读消息失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(int messageId, {int? groupId}) async {
    _log.i('标记消息已读, messageId=$messageId, groupId=$groupId');

    try {
      final message = await getMessage(messageId);
      if (message == null) {
        _log.w('消息不存在，无法标记已读: $messageId');
        return;
      }

      if (message.status == MessageStatus.read ||
          message.status == MessageStatus.recalled) {
        _log.d('消息已处于终态，跳过已读标记: $messageId, status=${message.status.name}');
        return;
      }

      await _databaseHelper.updateMessageStatus(messageId, MessageStatus.read);
      _log.d('本地消息状态已更新为已读: $messageId');

      await _readReceiptManager.enqueueReceipt(messageId, groupId: groupId);
    } catch (e) {
      _log.e('标记消息已读失败, messageId=$messageId', error: e);
      rethrow;
    }
  }

  @override
  Future<void> markConversationAsRead({
    required int targetId,
    int? groupId,
  }) async {
    _log.i('标记会话已读, targetId=$targetId, groupId=$groupId');

    try {
      final currentUserId = _getCurrentUserId();
      await _databaseHelper.markAsRead(currentUserId, groupId: groupId);

      final unreadMessages = await getUnreadMessages(currentUserId);
      final filteredMessages = groupId != null
          ? unreadMessages.where((m) => m.groupId == groupId).toList()
          : unreadMessages
                .where(
                  (m) =>
                      (m.fromId == targetId || m.toId == targetId) &&
                      m.groupId == null,
                )
                .toList();

      for (final msg in filteredMessages) {
        await _readReceiptManager.enqueueReceipt(msg.id!, groupId: groupId);
      }

      _log.i('会话已读标记完成, targetId=$targetId, 消息数=${filteredMessages.length}');
    } catch (e) {
      _log.e('标记会话已读失败, targetId=$targetId', error: e);
      rethrow;
    }
  }

  Future<int> _saveMessageToLocal(Message message) async {
    try {
      final id = await _databaseHelper.insertMessage(message);
      _log.d('消息已保存到本地数据库, id=$id');
      return id;
    } catch (e) {
      _log.e('保存消息到本地数据库失败', error: e);
      rethrow;
    }
  }

  Future<void> _updateMessageInDb(Message message) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'messages',
        {
          'content': message.content,
          'status': message.status.value,
          'timestamp': message.timestamp,
        },
        where: 'id = ?',
        whereArgs: [message.id],
      );
    } catch (e) {
      _log.e('更新消息状态失败, messageId=${message.id}', error: e);
    }
  }

  void _addToQueue(_PendingMessage pending) {
    if (_messageQueue.length >= _maxQueueSize) {
      _log.w('消息队列已满，丢弃最早的消息');
      _messageQueue.removeFirst();
    }

    _messageQueue.add(pending);
    _log.d('消息已加入队列, 当前队列长度: ${_messageQueue.length}');
    _processQueue();
  }

  void _processQueue() async {
    if (_isProcessing || _messageQueue.isEmpty) {
      return;
    }

    _isProcessing = true;

    while (_messageQueue.isNotEmpty) {
      final pending = _messageQueue.first;

      try {
        await _sendPendingMessage(pending);
        _messageQueue.removeFirst();
        _cleanupSentCache();
      } on StateError catch (e) {
        if (pending.retryCount < _maxRetryCount) {
          _log.w(
            '消息发送失败，准备重试 (${pending.retryCount + 1}/$_maxRetryCount)',
            error: e,
          );
          pending.retryCount++;
          _requeueWithDelay(pending);
        } else {
          _log.e('消息重试次数已达上限，标记为失败', error: e);
          await _markAsFailed(pending.message);
          _messageQueue.removeFirst();
        }
      } catch (e) {
        _log.e('消息发送异常', error: e);
        await _markAsFailed(pending.message);
        _messageQueue.removeFirst();
      }
    }

    _isProcessing = false;
  }

  Future<void> _sendPendingMessage(_PendingMessage pending) async {
    final message = pending.message;

    if (!_connectionManager.isConnected) {
      throw StateError('WebSocket未连接');
    }

    final protocolData = message.toProtocolJson();
    protocolData['clientId'] = message.id;

    _log.d('正在发送消息, messageId=${message.id}, type=${message.msgType.name}');
    _connectionManager.sendMessage(protocolData);

    final sentMessage = message.copyWith(status: MessageStatus.sent);
    await _updateMessageInDb(sentMessage);

    final dedupKey = _generateDedupKey(sentMessage);
    _sentMessageIds.add(dedupKey);

    _eventBus.fire(MessageSentEvent(message: sentMessage));
    _log.i('消息发送成功, messageId=${message.id}');
  }

  void _requeueWithDelay(_PendingMessage pending) {
    _messageQueue.removeFirst();
    _messageQueue.add(pending);

    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      _log.i('触发延迟重试');
      _processQueue();
    });
  }

  Future<void> _markAsFailed(Message message) async {
    final failedMessage = message.copyWith(status: MessageStatus.failed);
    await _updateMessageInDb(failedMessage);
    _log.e('消息标记为发送失败, messageId=${message.id}');
  }

  String _generateDedupKey(Message message) {
    final parts = [
      message.fromId.toString(),
      message.groupId?.toString() ?? message.toId.toString(),
      message.content,
      message.timestamp.toString(),
    ];
    return parts.join(':');
  }

  bool _isDuplicate(String dedupKey) {
    return _sentMessageIds.contains(dedupKey);
  }

  void _cleanupSentCache() {
    if (_sentMessageIds.length > 500) {
      final toRemove = _sentMessageIds.take(200).toList();
      for (final key in toRemove) {
        _sentMessageIds.remove(key);
      }
      _log.d('清理去重缓存, 当前缓存大小: ${_sentMessageIds.length}');
    }
  }

  bool _isValidMessageType(MessageType type) {
    return MessageType.values.contains(type);
  }

  int _getCurrentUserId() {
    return DateTime.now().millisecondsSinceEpoch ~/ 10000000;
  }

  void _startQueueProcessor() {
    _log.i('消息队列处理器已启动');
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _messageQueue.clear();
    _sentMessageIds.clear();
    _readReceiptManager.dispose();
    _log.i('MessageServiceImpl 已释放资源');
  }
}

class _PendingMessage {
  final Message message;
  final bool isGroup;
  int retryCount;

  _PendingMessage({
    required this.message,
    required this.isGroup,
    required this.retryCount,
  });
}

class ReadReceiptManager {
  final ConnectionManager _connectionManager;
  final Duration _batchDelay;

  final Set<int> _pendingReceipts = {};
  Timer? _batchTimer;
  bool _isDisposed = false;

  static const int _maxBatchSize = 50;

  final Logger _log = AppLogger.instance;

  ReadReceiptManager({
    required ConnectionManager connectionManager,
    required Duration batchDelay,
  }) : _connectionManager = connectionManager,
       _batchDelay = batchDelay;

  Future<void> enqueueReceipt(int messageId, {int? groupId}) async {
    if (_isDisposed) {
      return;
    }

    if (_pendingReceipts.contains(messageId)) {
      return;
    }

    if (_pendingReceipts.length >= _maxBatchSize) {
      await _sendBatchImmediately();
    }

    _pendingReceipts.add(messageId);
    _scheduleBatchSend();
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
        _log.i('已读回执批量发送成功, messageIds=$messageIds');
      } else {
        _log.w('网络未连接，已读回执缓存到本地');
        for (final msgId in messageIds) {
          _pendingReceipts.add(msgId);
        }
      }
    } catch (e) {
      _log.e('已读回执发送失败', error: e);
      for (final msgId in messageIds) {
        _pendingReceipts.add(msgId);
      }
    }
  }

  Future<void> _sendBatchImmediately() async {
    _batchTimer?.cancel();
    await _sendBatch();
  }

  void dispose() {
    _isDisposed = true;
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_pendingReceipts.isNotEmpty) {
      _log.w('ReadReceiptManager 销毁时仍有 ${_pendingReceipts.length} 条待发送回执');
      _pendingReceipts.clear();
    }

    _log.i('ReadReceiptManager 已释放资源');
  }
}
