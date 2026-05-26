import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'models/message_hive.dart';
import 'models/conversation_hive.dart';

/// Hive 数据查看器 - 用于开发和调试
///
/// 使用方法：
/// 1. 在 main() 中调用 await HiveViewer.init();
/// 2. 随时调用 HiveViewer.printAllData() 查看所有数据
/// 3. 调用 HiveViewer.exportToJson() 导出为 JSON
class HiveViewer {
  static bool _isInitialized = false;

  /// 初始化 Hive 查看器（必须先调用）
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        await Hive.initFlutter();
      } else {
        String hiveDir;
        try {
          final appDir = await getApplicationDocumentsDirectory();
          hiveDir = '${appDir.path}/hive_db';
        } catch (e) {
          hiveDir = '${Directory.current.path}/hive_db';
        }
        Hive.init(hiveDir);
      }

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MessageHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ConversationHiveAdapter());
      }

      _isInitialized = true;
      print('[HiveViewer] ✅ 初始化完成');
    } catch (e) {
      print('[HiveViewer] ❌ 初始化失败: $e');
    }
  }

  /// 打印所有存储的数据到控制台
  static Future<void> printAllData() async {
    if (!_isInitialized) {
      print('[HiveViewer] ❌ 请先调用 init()');
      return;
    }

    print('\n' + '=' * 60);
    print('🐝 HIVE 数据查看器');
    print('=' * 60);

    try {
      // 使用已打开的 Box，不关闭它（避免影响 HiveStorage）
      final messagesBox = Hive.isBoxOpen('messages')
          ? Hive.box<MessageHive>('messages')
          : await Hive.openBox<MessageHive>('messages');

      final conversationsBox = Hive.isBoxOpen('conversations')
          ? Hive.box<ConversationHive>('conversations')
          : await Hive.openBox<ConversationHive>('conversations');

      print('\n📊 统计信息:');
      print('   📨 消息数量: ${messagesBox.length}');
      print('   💬 会话数量: ${conversationsBox.length}');

      // 打印所有消息
      print('\n' + '-' * 60);
      print('📨 消息列表 (${messagesBox.length} 条):');
      print('-' * 60);

      if (messagesBox.isEmpty) {
        print('   (空)');
      } else {
        for (final key in messagesBox.keys) {
          final msg = messagesBox.get(key)!;
          print('   [$key] ${msg.fromId} → ${msg.toId}: "${msg.content}" '
              '[${_formatTimestamp(msg.timestamp)}]');
        }
      }

      // 打印所有会话
      print('\n' + '-' * 60);
      print('💬 会话列表 (${conversationsBox.length} 个):');
      print('-' * 60);

      if (conversationsBox.isEmpty) {
        print('   (空)');
      } else {
        for (final key in conversationsBox.keys) {
          final conv = conversationsBox.get(key)!;
          final targetInfo = conv.targetType == 1 ? '私聊' : '群聊';
          print('   [$key] 用户${conv.userId} → $targetInfo 目标${conv.targetId} '
              '[未读: ${conv.unreadCount}]');
          if (conv.lastMessage != null) {
            print('       最后消息: "${conv.lastMessage!.content}"');
          }
        }
      }

      print('\n' + '=' * 60);
      print('📍 存储路径: ${await _getStoragePath()}');
      print('=' * 60 + '\n');

      // ⚠️ 不要关闭 Box！HiveStorage 还在使用
    } catch (e) {
      print('[HiveViewer] ❌ 读取失败: $e');
    }
  }

  /// 导出所有数据为 JSON 字符串
  static Future<String> exportToJson() async {
    if (!_isInitialized) {
      throw StateError('请先调用 init()');
    }

    final messagesBox = Hive.isBoxOpen('messages')
        ? Hive.box<MessageHive>('messages')
        : await Hive.openBox<MessageHive>('messages');

    final conversationsBox = Hive.isBoxOpen('conversations')
        ? Hive.box<ConversationHive>('conversations')
        : await Hive.openBox<ConversationHive>('conversations');

    final Map<String, dynamic> exportData = {
      'exportTime': DateTime.now().toIso8601String(),
      'statistics': {
        'messageCount': messagesBox.length,
        'conversationCount': conversationsBox.length,
      },
      'messages': messagesBox.values.map((m) => m.toJson()).toList(),
      'conversations': conversationsBox.values.map((c) => c.toJson()).toList(),
    };

    final jsonString = _prettyPrintJson(exportData);
    return jsonString;
  }

  /// 将数据导出到文件
  static Future<String> exportToFile({String? fileName}) async {
    final json = await exportToJson();

    if (kIsWeb) {
      print('[HiveViewer] 🌐 Web 端无法直接写入文件，请使用控制台输出');
      print(json);
      return json;
    } else {
      String basePath;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        basePath = appDir.path;
      } catch (e) {
        basePath = Directory.current.path;
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = fileName ?? 'hive_export_$timestamp.json';
      final file = File('$basePath/$name');

      await file.writeAsString(json, flush: true);

      final path = file.path;
      print('[HiveViewer] ✅ 已导出到: $path');
      return path;
    }
  }

  /// 清空所有数据（慎用！）
  static Future<void> clearAllData() async {
    final messagesBox = Hive.isBoxOpen('messages')
        ? Hive.box<MessageHive>('messages')
        : await Hive.openBox<MessageHive>('messages');

    final conversationsBox = Hive.isBoxOpen('conversations')
        ? Hive.box<ConversationHive>('conversations')
        : await Hive.openBox<ConversationHive>('conversations');

    final msgCount = messagesBox.length;
    final convCount = conversationsBox.length;

    await messagesBox.clear();
    await conversationsBox.clear();

    print('[HiveViewer] 🗑️ 已清除 $msgCount 条消息和 $convCount 个会话');
  }

  /// 获取存储路径
  static Future<String> _getStoragePath() async {
    if (kIsWeb) {
      return 'IndexedDB (浏览器内部)';
    } else {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        return '${appDir.path}/hive_db/';
      } catch (e) {
        return '${Directory.current.path}/hive_db/';
      }
    }
  }

  /// 格式化时间戳
  static String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  /// JSON 格式化打印
  static String _prettyPrintJson(dynamic json, {int indent = 2}) {
    final spacer = ' ' * indent;
    final nextSpacer = ' ' * (indent + 2);

    if (json is Map) {
      if (json.isEmpty) return '{}';
      var buffer = StringBuffer('{\n');
      json.forEach((key, value) {
        buffer.write('$spacer"$key": ${_prettyPrintJson(value, indent: indent + 2)},\n');
      });
      final str = buffer.toString();
      return str.replaceFirst(',\n', '\n') + '$spacer}';
    } else if (json is List) {
      if (json.isEmpty) return '[]';
      var buffer = StringBuffer('[\n');
      for (var item in json) {
        buffer.write('$nextSpacer${_prettyPrintJson(item, indent: indent + 2)},\n');
      }
      final str = buffer.toString();
      return str.replaceFirst(',\n', '\n') + '$nextSpacer]';
    } else if (json is String) {
      return '"$json"';
    } else if (json is int || json is double || json is bool) {
      return json.toString();
    } else if (json == null) {
      return 'null';
    } else {
      return json.toString();
    }
  }
}
