import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/message.dart';
import '../model/conversation.dart';
import 'storage_interface.dart';

class WebStorage implements StorageInterface {
  static final WebStorage _instance = WebStorage._internal();
  factory WebStorage() => _instance;
  WebStorage._internal();

  static const String _messagesKey = 'im_messages';
  static const String _conversationsKey = 'im_conversations';
  SharedPreferences? _prefs;

  @override
  Future<void> init({int? userId}) async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  List<Map<String, dynamic>> _getMessagesList(SharedPreferences prefs) {
    final String? jsonStr = prefs.getString(_messagesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveMessagesList(SharedPreferences prefs, List<Map<String, dynamic>> messages) async {
    await prefs.setString(_messagesKey, jsonEncode(messages));
  }

  List<Map<String, dynamic>> _getConversationsList(SharedPreferences prefs) {
    final String? jsonStr = prefs.getString(_conversationsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveConversationsList(SharedPreferences prefs, List<Map<String, dynamic>> conversations) async {
    await prefs.setString(_conversationsKey, jsonEncode(conversations));
  }

  int _generateId(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 1;
    final maxId = items.map((item) => item['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  @override
  Future<int> insertMessage(Message message) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);

    final messageMap = _messageToMap(message);
    if (messageMap['id'] == null) {
      messageMap['id'] = _generateId(messages);
    }

    messages.add(messageMap);
    await _saveMessagesList(prefs, messages);
    return messageMap['id'] as int;
  }

  @override
  Future<List<Message>> getMessages({
    required int targetId,
    int? groupId,
    int? currentUserId,
    int page = 1,
    int size = 20,
  }) async {
    final prefs = await _preferences;
    var messages = _getMessagesList(prefs);

    if (groupId != null) {
      messages = messages.where((m) => m['group_id'] == groupId).toList();
    } else {
      final userId = currentUserId ?? targetId;
      messages = messages.where((m) =>
        (m['from_id'] == userId && m['to_id'] == targetId) ||
        (m['from_id'] == targetId && m['to_id'] == userId)
      ).toList();
    }

    messages.sort((a, b) => ((b['timestamp'] as int?) ?? 0).compareTo((a['timestamp'] as int?) ?? 0));

    final offset = (page - 1) * size;
    final pagedMessages = messages.skip(offset).take(size).toList();

    return pagedMessages.map((map) => _mapToMessage(map)).toList();
  }

  @override
  Future<Message?> getLastMessage(int targetId, {int? groupId}) async {
    final prefs = await _preferences;
    var messages = _getMessagesList(prefs);

    if (groupId != null) {
      messages = messages.where((m) => m['group_id'] == groupId).toList();
    } else {
      messages = messages.where((m) =>
        m['from_id'] == targetId || m['to_id'] == targetId
      ).toList();
    }

    messages.sort((a, b) => ((b['timestamp'] as int?) ?? 0).compareTo((a['timestamp'] as int?) ?? 0));

    if (messages.isNotEmpty) {
      return _mapToMessage(messages.first);
    }
    return null;
  }

  @override
  Future<int?> getMaxSeq(int groupId) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs)
        .where((m) => m['group_id'] == groupId && m['seq'] != null)
        .toList();

    if (messages.isEmpty) return null;

    int? maxSeq;
    for (final m in messages) {
      final s = m['seq'] as int?;
      if (s != null && (maxSeq == null || s > maxSeq)) {
        maxSeq = s;
      }
    }
    return maxSeq;
  }

  @override
  Future<Message?> getMessageById(int messageId) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);

    final messageMap = messages.where((m) => m['id'] == messageId).toList();
    if (messageMap.isNotEmpty) {
      return _mapToMessage(messageMap.first);
    }
    return null;
  }

  @override
  Future<Message?> getMessageByMid(int mid) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);

    final messageMap = messages.where((m) => m['mid'] == mid).toList();
    if (messageMap.isNotEmpty) {
      return _mapToMessage(messageMap.first);
    }
    return null;
  }

  @override
  Future<void> updateMessage(Message message) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);

    final index = messages.indexWhere((m) => m['id'] == message.id);
    if (index != -1) {
      messages[index] = _messageToMap(message);
      await _saveMessagesList(prefs, messages);
    }
  }

  @override
  Future<void> updateMessageDelivered(int mid) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);

    final index = messages.indexWhere((m) => m['mid'] == mid);
    if (index != -1) {
      messages[index]['delivered'] = 1;
      await _saveMessagesList(prefs, messages);
    }
  }

  @override
  Future<void> updateMessageStatus(int messageId, MessageStatus status) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);

    final index = messages.indexWhere((m) => m['id'] == messageId);
    if (index != -1) {
      messages[index]['status'] = status.value;
      await _saveMessagesList(prefs, messages);
    }
  }

  @override
  Future<void> updateMessageContent(int messageId, String content, MessageStatus status) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);

    final index = messages.indexWhere((m) => m['id'] == messageId);
    if (index != -1) {
      messages[index]['content'] = content;
      messages[index]['status'] = status.value;
      await _saveMessagesList(prefs, messages);
    }
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);

    return messages.where((m) =>
      m['to_id'] == userId && (m['status'] as int? ?? 0) < 3
    ).length;
  }

  @override
  Future<void> markAsRead(int userId, {int? targetId, int? groupId}) async {
    final prefs = await _preferences;
    final messages = _getMessagesList(prefs);
    final conversations = _getConversationsList(prefs);

    for (var i = 0; i < messages.length; i++) {
      if (messages[i]['to_id'] == userId && (messages[i]['status'] as int? ?? 0) < 3) {
        final matchesGroup = groupId != null && messages[i]['group_id'] == groupId;
        final matchesPrivate = targetId != null &&
            messages[i]['group_id'] == null &&
            ((messages[i]['from_id'] == targetId && messages[i]['to_id'] == userId) ||
                (messages[i]['from_id'] == userId && messages[i]['to_id'] == targetId));

        if (matchesGroup || matchesPrivate) {
          messages[i]['status'] = 3;
        }
      }
    }

    await _saveMessagesList(prefs, messages);

    for (var i = 0; i < conversations.length; i++) {
      final isTargetConversation = conversations[i]['user_id'] == userId &&
          ((groupId != null &&
                  conversations[i]['target_type'] == 2 &&
                  conversations[i]['target_id'] == groupId) ||
              (targetId != null &&
                  conversations[i]['target_type'] == 1 &&
                  conversations[i]['target_id'] == targetId));

      if (isTargetConversation) {
        conversations[i]['unread_count'] = 0;
      }
    }

    await _saveConversationsList(prefs, conversations);
  }

  @override
  Future<int> insertConversation(Conversation conversation) async {
    final prefs = await _preferences;
    final conversations = _getConversationsList(prefs);

    final convMap = _conversationToMap(conversation);
    if (convMap['id'] == null) {
      convMap['id'] = _generateId(conversations);
    }

    final existingIndex = conversations.indexWhere((c) => c['id'] == convMap['id']);
    if (existingIndex != -1) {
      conversations[existingIndex] = convMap;
    } else {
      conversations.add(convMap);
    }

    await _saveConversationsList(prefs, conversations);
    return convMap['id'] as int;
  }

  @override
  Future<List<Conversation>> getConversations(int userId) async {
    final prefs = await _preferences;
    var conversations = _getConversationsList(prefs);

    conversations = conversations.where((c) => c['user_id'] == userId).toList();
    conversations.sort((a, b) => ((b['update_time'] as int?) ?? 0).compareTo((a['update_time'] as int?) ?? 0));

    return conversations.map((map) => _mapToConversation(map)).toList();
  }

  @override
  Future<void> updateConversation(Conversation conversation) async {
    final prefs = await _preferences;
    final conversations = _getConversationsList(prefs);

    final index = conversations.indexWhere((c) => c['id'] == conversation.id);
    if (index != -1) {
      conversations[index] = _conversationToMap(conversation);
      await _saveConversationsList(prefs, conversations);
    }
  }

  @override
  Future<void> updateUnreadCount(int conversationId, int count) async {
    final prefs = await _preferences;
    final conversations = _getConversationsList(prefs);

    final index = conversations.indexWhere((c) => c['id'] == conversationId);
    if (index != -1) {
      conversations[index]['unread_count'] = count;
      await _saveConversationsList(prefs, conversations);
    }
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    final prefs = await _preferences;
    final conversations = _getConversationsList(prefs);

    conversations.removeWhere((c) => c['id'] == conversationId);
    await _saveConversationsList(prefs, conversations);
  }

  Map<String, dynamic> _messageToMap(Message message) {
    return {
      'id': message.id,
      'mid': message.mid,
      'seq': message.seq,
      'from_id': message.fromId,
      'to_id': message.toId,
      'group_id': message.groupId,
      'content': message.content,
      'msg_type': message.msgType.value,
      'status': message.status.value,
      'delivered': message.delivered ? 1 : 0,
      'timestamp': message.timestamp,
      'local_path': message.localPath,
    };
  }

  Message _mapToMessage(Map<String, dynamic> map) {
    return Message.fromJson({
      'id': map['id'],
      'mid': map['mid'],
      'seq': map['seq'],
      'fromId': map['from_id'],
      'toId': map['to_id'],
      'groupId': map['group_id'],
      'content': map['content'],
      'msgType': map['msg_type'],
      'status': map['status'],
      'delivered': (map['delivered'] as int? ?? 0) == 1,
      'timestamp': map['timestamp'],
      'localPath': map['local_path'],
    });
  }

  Map<String, dynamic> _conversationToMap(Conversation conversation) {
    return {
      'id': conversation.id,
      'user_id': conversation.userId,
      'target_type': conversation.targetType.value,
      'target_id': conversation.targetId,
      'last_message': conversation.lastMessage?.toJson(),
      'unread_count': conversation.unreadCount,
      'update_time': conversation.updateTime,
    };
  }

  Conversation _mapToConversation(Map<String, dynamic> map) {
    return Conversation.fromJson({
      'id': map['id'],
      'userId': map['user_id'],
      'targetType': map['target_type'],
      'targetId': map['target_id'],
      'lastMessage': map['last_message'] != null
          ? _mapDecode(map['last_message'])
          : null,
      'unreadCount': map['unread_count'],
      'updateTime': map['update_time'],
    });
  }

  dynamic _mapDecode(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  @override
  Future<void> close() async {
    _prefs = null;
  }
}
