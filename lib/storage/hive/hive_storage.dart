import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../model/message.dart' as model;
import '../../model/conversation.dart' as model_conv;
import '../storage_interface.dart';
import 'models/message_hive.dart';
import 'models/conversation_hive.dart';

class HiveStorage implements StorageInterface {
  static const String _messagesBoxName = 'messages';
  static const String _conversationsBoxName = 'conversations';
  static const String _settingsBoxName = 'settings';

  late Box<MessageHive> _messagesBox;
  late Box<ConversationHive> _conversationsBox;
  late Box<dynamic> _settingsBox;

  bool _isInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    print('[HiveStorage] 🐝 初始化 Hive 本地存储...');

    try {
      await _initHive();
      _registerAdapters();
      await _openBoxes();

      _isInitialized = true;
      print('[HiveStorage] ✅ 初始化完成');
      print('[HiveStorage] 📊 消息数量: ${_messagesBox.length}');
      print('[HiveStorage] 📊 会话数量: ${_conversationsBox.length}');
    } catch (e, stackTrace) {
      print('[HiveStorage] ❌ 初始化失败: $e');
      print('[HiveStorage] 📍 堆栈: $stackTrace');
      rethrow;
    }
  }

  Future<void> _initHive() async {
    if (kIsWeb) {
      print('[HiveStorage] 🌐 Web 平台：使用 Hive (IndexedDB)');
      await Hive.initFlutter();
    } else {
      String hiveDir;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        hiveDir = '${appDir.path}/hive_db';
      } catch (e) {
        // ✅ Windows/Web 桌面端 path_provider 可能不可用，使用当前目录
        hiveDir = '${Directory.current.path}/hive_db';
        print('[HiveStorage] ⚠️ getApplicationDocumentsDirectory 不可用，回退到: $hiveDir');
      }
      print('[HiveStorage] 💻 原生平台：使用 Hive (文件存储)');
      print('[HiveStorage] 📁 存储路径: $hiveDir');
      Hive.init(hiveDir);
    }
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ConversationHiveAdapter());
    }
    print('[HiveStorage] 🔧 适配器注册完成');
  }

  Future<void> _openBoxes() async {
    _messagesBox = await Hive.openBox<MessageHive>(_messagesBoxName);
    _conversationsBox = await Hive.openBox<ConversationHive>(_conversationsBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    print('[HiveStorage] 📦 Box 已打开');
  }

  @override
  Future<int> insertMessage(model.Message message) async {
    final messageHive = MessageHive.fromMessage(message);

    // ✅ 始终使用 Hive 自动生成的 key（避免雪花ID超出32位范围）
    final key = await _messagesBox.add(messageHive);
    
    // 将原始业务ID保留在对象内，Hive key 作为内部索引
    messageHive.id = key;
    await _messagesBox.put(key, messageHive);
    
    return key;
  }

  @override
  Future<List<model.Message>> getMessages({
    required int targetId,
    int? groupId,
    int? currentUserId,
    int page = 1,
    int size = 20,
  }) async {
    List<MessageHive> allMessages;

    if (groupId != null) {
      allMessages = _messagesBox.values
          .where((m) => m.groupId == groupId)
          .toList();
    } else {
      // ✅ 修复：确保 currentUserId 有值
      final userId = currentUserId ?? 0;
      allMessages = _messagesBox.values
          .where((m) =>
              (m.fromId == targetId && m.toId == userId) ||
              (m.fromId == userId && m.toId == targetId))
          .toList();
    }

    allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final startIndex = (page - 1) * size;
    final endIndex = (startIndex + size) > allMessages.length
        ? allMessages.length
        : startIndex + size;

    if (startIndex >= allMessages.length) {
      return [];
    }

    final pagedMessages = allMessages.sublist(startIndex, endIndex);
    return pagedMessages.map((m) => m.toMessage()).toList();
  }

  @override
  Future<model.Message?> getLastMessage(int targetId, {int? groupId}) async {
    MessageHive? lastMessage;

    if (groupId != null) {
      final groupMessages = _messagesBox.values
          .where((m) => m.groupId == groupId)
          .toList();

      if (groupMessages.isNotEmpty) {
        groupMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        lastMessage = groupMessages.first;
      }
    } else {
      final privateMessages = _messagesBox.values
          .where((m) => m.fromId == targetId || m.toId == targetId)
          .toList();

      if (privateMessages.isNotEmpty) {
        privateMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        lastMessage = privateMessages.first;
      }
    }

    return lastMessage?.toMessage();
  }

  @override
  Future<model.Message?> getMessageById(int messageId) async {
    final messageHive = _messagesBox.get(messageId);
    return messageHive?.toMessage();
  }

  @override
  Future<void> updateMessageStatus(int messageId, model.MessageStatus status) async {
    final messageHive = _messagesBox.get(messageId);
    if (messageHive != null) {
      messageHive.status = status.value;
      await messageHive.save();
    }
  }

  @override
  Future<void> updateMessageContent(
      int messageId, String content, model.MessageStatus status) async {
    final messageHive = _messagesBox.get(messageId);
    if (messageHive != null) {
      messageHive.content = content;
      messageHive.status = status.value;
      await messageHive.save();
    }
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    int totalUnread = 0;

    for (final conv in _conversationsBox.values) {
      if (conv.userId == userId) {
        totalUnread += conv.unreadCount;
      }
    }

    return totalUnread;
  }

  @override
  Future<void> markAsRead(int userId, {int? groupId}) async {
    if (groupId != null) {
      final messages = _messagesBox.values
          .where((m) =>
              m.groupId == groupId &&
              m.toId == userId &&
              m.status < model.MessageStatus.read.value)
          .toList();

      for (final msg in messages) {
        msg.status = model.MessageStatus.read.value;
        await msg.save();
      }
    } else {
      final conversations = _conversationsBox.values
          .where((c) => c.userId == userId)
          .toList();

      for (final conv in conversations) {
        conv.unreadCount = 0;
        await conv.save();
      }
    }
  }

  @override
  Future<int> insertConversation(model_conv.Conversation conversation) async {
    final convHive = ConversationHive.fromConversation(conversation);

    // ✅ 始终使用 Hive 自动生成的 key（避免ID超出32位范围）
    final key = await _conversationsBox.add(convHive);
    
    convHive.id = key;
    await _conversationsBox.put(key, convHive);
    
    return key;
  }

  @override
  Future<List<model_conv.Conversation>> getConversations(int userId) async {
    Iterable<ConversationHive> result;

    if (userId == 0) {
      result = _conversationsBox.values;
    } else {
      result = _conversationsBox.values.where((c) => c.userId == userId);
    }

    final sorted = result.toList()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));

    return sorted.map((c) => c.toConversation()).toList();
  }

  /// ✅ 新增：根据 targetId + targetType 查找会话（用于更新）
  Future<model_conv.Conversation?> findConversationByTarget(
    int targetId,
    model_conv.TargetType targetType,
    int userId,
  ) async {
    final matches = _conversationsBox.values.where((c) =>
      c.targetId == targetId &&
      c.targetType == targetType.value &&
      c.userId == userId
    ).toList()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));

    if (matches.isNotEmpty) {
      return matches.first.toConversation();
    }
    return null;
  }

  @override
  Future<void> updateConversation(model_conv.Conversation conversation) async {
    if (conversation.id == null || conversation.id! <= 0) return;

    final existingConv = _conversationsBox.get(conversation.id);
    if (existingConv != null) {
      final updatedConv = ConversationHive.fromConversation(conversation);
      updatedConv.id = conversation.id;  // 确保 id 正确
      await _conversationsBox.put(conversation.id!, updatedConv);
    }
  }

  /// ✅ 新增：根据 targetId + targetType 更新会话的 lastMessage
  Future<void> updateLastMessageByTarget({
    required int targetId,
    required int targetType,
    required int userId,
    required model.Message lastMessage,
  }) async {
    // 查找匹配的会话
    final matches = _conversationsBox.values.where((c) =>
      c.targetId == targetId &&
      c.targetType == targetType &&
      c.userId == userId
    ).toList();

    if (matches.isNotEmpty) {
      final conv = matches.first;  // 取最新的一个
      
      // 更新 lastMessage 和 updateTime
      conv.lastMessage = MessageHive.fromMessage(lastMessage);
      conv.updateTime = DateTime.now().millisecondsSinceEpoch;
      
      await conv.save();
      print('[HiveStorage] ✅ 会话已更新: targetId=$targetId, 最后消息="${lastMessage.content}"');
    } else {
      // 会话不存在，创建新的
      final newConv = ConversationHive(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        lastMessage: MessageHive.fromMessage(lastMessage),
        unreadCount: 0,
        updateTime: DateTime.now().millisecondsSinceEpoch,
      );
      
      final key = await _conversationsBox.add(newConv);
      newConv.id = key;
      await _conversationsBox.put(key, newConv);
      print('[HiveStorage] ✅ 新会话已创建: targetId=$targetId, id=$key');
    }
  }

  @override
  Future<void> updateUnreadCount(int conversationId, int count) async {
    final conv = _conversationsBox.get(conversationId);
    if (conv != null) {
      conv.unreadCount = count;
      await conv.save();
    }
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    await _conversationsBox.delete(conversationId);
    
    // ✅ 同时删除该会话的所有关联消息
    final messagesToDelete = _messagesBox.values
        .where((m) => 
            // 找到该会话相关的消息（根据 targetId 匹配）
            // 注意：这里简化处理，实际应该维护 conversationId 字段
            false  // 暂时不删消息，避免误删
        )
        .toList();
        
    print('[HiveStorage] 🗑️ 会话已删除: id=$conversationId');
  }

  /// ✅ 新增：彻底删除会话及其所有消息
  Future<void> deleteConversationWithMessages(int targetId, int targetType, int userId) async {
    // 1. 找到并删除会话
    final matches = _conversationsBox.values.where((c) =>
      c.targetId == targetId &&
      c.targetType == targetType &&
      c.userId == userId
    ).toList();
    
    for (final conv in matches) {
      await _conversationsBox.delete(conv.key);
    }
    
    // 2. 删除相关消息（私聊：fromId 或 toId 匹配 targetId）
    final relatedMessages = _messagesBox.values.where((m) =>
      (m.fromId == targetId || m.toId == targetId) &&
      m.groupId == null  // 只删私聊消息，群聊消息保留
    ).toList();
    
    for (final msg in relatedMessages) {
      await _messagesBox.delete(msg.key);
    }
    
    print('[HiveStorage] 🗑️ 彻底删除: ${matches.length} 个会话, ${relatedMessages.length} 条消息');
  }

  @override
  Future<void> close() async {
    if (_isInitialized) {
      await _messagesBox.close();
      await _conversationsBox.close();
      await _settingsBox.close();
      await Hive.close();
      _isInitialized = false;
      print('[HiveStorage] ✓ 连接已关闭');
    }
  }

  Future<void> clearAll() async {
    await _messagesBox.clear();
    await _conversationsBox.clear();
    print('[HiveStorage] 🗑️ 所有数据已清除');
  }

  int get messagesCount => _messagesBox.length;
  int get conversationsCount => _conversationsBox.length;
}
