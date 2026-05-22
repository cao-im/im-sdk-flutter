import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert' show jsonDecode;
import '../model/message.dart';
import '../model/conversation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'cao_im.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_id INTEGER NOT NULL,
        to_id INTEGER NOT NULL,
        group_id INTEGER,
        content TEXT NOT NULL,
        msg_type INTEGER NOT NULL DEFAULT 0,
        status INTEGER NOT NULL DEFAULT 0,
        timestamp INTEGER NOT NULL,
        local_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        target_type INTEGER NOT NULL DEFAULT 1,
        target_id INTEGER NOT NULL,
        last_message TEXT,
        unread_count INTEGER NOT NULL DEFAULT 0,
        update_time INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_from_to ON messages(from_id, to_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_group ON messages(group_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_conversations_user ON conversations(user_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  }

  Future<int> insertMessage(Message message) async {
    final db = await database;
    return await db.insert(
      'messages',
      _messageToMap(message),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Message>> getMessages({
    required int targetId,
    int? groupId,
    int? currentUserId,
    int page = 1,
    int size = 20,
  }) async {
    final db = await database;
    final offset = (page - 1) * size;

    List<Map<String, dynamic>> maps;

    if (groupId != null) {
      maps = await db.query(
        'messages',
        where: 'group_id = ?',
        whereArgs: [groupId],
        orderBy: 'timestamp DESC',
        limit: size,
        offset: offset,
      );
    } else {
      final userId = currentUserId ?? targetId;
      maps = await db.query(
        'messages',
        where: '(from_id = ? AND to_id = ?) OR (from_id = ? AND to_id = ?)',
        whereArgs: [userId, targetId, targetId, userId],
        orderBy: 'timestamp DESC',
        limit: size,
        offset: offset,
      );
    }

    return maps.map((map) => _mapToMessage(map)).toList();
  }

  Future<Message?> getLastMessage(int targetId, {int? groupId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (groupId != null) {
      maps = await db.query(
        'messages',
        where: 'group_id = ?',
        whereArgs: [groupId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
    } else {
      maps = await db.query(
        'messages',
        where: '(from_id = ? OR to_id = ?)',
        whereArgs: [targetId, targetId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
    }

    if (maps.isNotEmpty) {
      return _mapToMessage(maps.first);
    }
    return null;
  }

  Future<void> updateMessageStatus(int messageId, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status.value},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<int> getUnreadCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE to_id = ? AND status < 3',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markAsRead(int userId, {int? groupId}) async {
    final db = await database;

    if (groupId != null) {
      await db.update(
        'messages',
        {'status': 3},
        where: 'to_id = ? AND group_id = ? AND status < 3',
        whereArgs: [userId, groupId],
      );
    } else {
      await db.update(
        'messages',
        {'status': 3},
        where: 'to_id = ? AND status < 3',
        whereArgs: [userId],
      );
    }
  }

  Future<int> insertConversation(Conversation conversation) async {
    final db = await database;
    return await db.insert(
      'conversations',
      _conversationToMap(conversation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Conversation>> getConversations(int userId) async {
    final db = await database;
    final maps = await db.query(
      'conversations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'update_time DESC',
    );

    return maps.map((map) => _mapToConversation(map)).toList();
  }

  Future<void> updateConversation(Conversation conversation) async {
    final db = await database;
    await db.update(
      'conversations',
      _conversationToMap(conversation),
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<void> updateUnreadCount(int conversationId, int count) async {
    final db = await database;
    await db.update(
      'conversations',
      {'unread_count': count},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteConversation(int conversationId) async {
    final db = await database;
    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Map<String, dynamic> _messageToMap(Message message) {
    return {
      'id': message.id,
      'from_id': message.fromId,
      'to_id': message.toId,
      'group_id': message.groupId,
      'content': message.content,
      'msg_type': message.msgType.value,
      'status': message.status.value,
      'timestamp': message.timestamp,
      'local_path': message.localPath,
    };
  }

  Message _mapToMessage(Map<String, dynamic> map) {
    return Message.fromJson({
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
          ? mapDecode(map['last_message'])
          : null,
      'unreadCount': map['unread_count'],
      'updateTime': map['update_time'],
    });
  }

  dynamic mapDecode(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
