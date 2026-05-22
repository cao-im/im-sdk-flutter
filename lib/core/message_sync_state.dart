import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

class SyncState {
  final int? lastMessageId;
  final int? lastTimestamp;
  final int? lastSyncTime;
  final int syncCount;

  const SyncState({
    this.lastMessageId,
    this.lastTimestamp,
    this.lastSyncTime,
    this.syncCount = 0,
  });

  SyncState copyWith({
    int? lastMessageId,
    int? lastTimestamp,
    int? lastSyncTime,
    int? syncCount,
  }) {
    return SyncState(
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncCount: syncCount ?? this.syncCount,
    );
  }
}

class MessageSyncState {
  static const String _keyLastMessageId = 'last_sync_message_id';
  static const String _keyLastTimestamp = 'last_sync_timestamp';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keySyncCount = 'sync_count';

  MessageSyncState._();

  static final Logger _log = AppLogger.instance;

  static Future<SyncState> getSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return SyncState(
        lastMessageId: prefs.getInt(_keyLastMessageId),
        lastTimestamp: prefs.getInt(_keyLastTimestamp),
        lastSyncTime: prefs.getInt(_keyLastSyncTime),
        syncCount: prefs.getInt(_keySyncCount) ?? 0,
      );
    } catch (e) {
      _log.e('[MessageSyncState] 获取同步状态失败', error: e);
      return const SyncState();
    }
  }

  static Future<void> updateLastMessageId(int messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastMessageId, messageId);
      _log.d('更新最后消息ID: $messageId');
    } catch (e) {
      _log.e('更新最后消息ID失败', error: e);
    }
  }

  static Future<void> updateLastTimestamp(int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastTimestamp, timestamp);
      _log.d('更新最后时间戳: $timestamp');
    } catch (e) {
      _log.e('更新最后时间戳失败', error: e);
    }
  }

  static Future<void> updateLastSyncTime(int syncTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_keySyncCount) ?? 0;
      await prefs.setInt(_keyLastSyncTime, syncTime);
      await prefs.setInt(_keySyncCount, currentCount + 1);
      _log.d(
        '更新同步时间: ${DateTime.fromMillisecondsSinceEpoch(syncTime).toIso8601String()}, 同步次数: ${currentCount + 1}',
      );
    } catch (e) {
      _log.e('更新同步时间失败', error: e);
    }
  }

  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastMessageId);
      await prefs.remove(_keyLastTimestamp);
      await prefs.remove(_keyLastSyncTime);
      await prefs.remove(_keySyncCount);
      _log.i('同步状态已重置');
    } catch (e) {
      _log.e('重置同步状态失败', error: e);
    }
  }

  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final state = await getSyncState();
      return {
        'lastMessageId': state.lastMessageId,
        'lastTimestamp': state.lastTimestamp,
        'lastSyncTime': state.lastSyncTime != null
            ? DateTime.fromMillisecondsSinceEpoch(
                state.lastSyncTime!,
              ).toIso8601String()
            : null,
        'syncCount': state.syncCount,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
