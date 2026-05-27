import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'storage_interface.dart';
import 'drift/drift_storage.dart';

class StorageFactory {
  static StorageInterface? _instance;

  static Future<StorageInterface> getInstance() async {
    if (_instance != null) return _instance!;

    print('[StorageFactory] 🗄️ 初始化 DriftStorage (全平台 SQLite 持久化)...');

    try {
      _instance = DriftStorage();
      await _instance!.init();

      if (kIsWeb) {
        print('[StorageFactory] ✅ Web 平台: WebDatabase (IndexedDB/OPFS)');
      } else if (Platform.isWindows) {
        print('[StorageFactory] ✅ Windows 平台: NativeDatabase (文件持久化)');
      } else if (Platform.isLinux) {
        print('[StorageFactory] ✅ Linux 平台: NativeDatabase (文件持久化)');
      } else if (Platform.isMacOS) {
        print('[StorageFactory] ✅ macOS 平台: NativeDatabase (文件持久化)');
      } else if (Platform.isAndroid) {
        print('[StorageFactory] ✅ Android 平台: NativeDatabase (文件持久化)');
      } else if (Platform.isIOS) {
        print('[StorageFactory] ✅ iOS 平台: NativeDatabase (文件持久化)');
      }

      print('[StorageFactory] ✅ 初始化完成: ${_instance.runtimeType}');
    } catch (e, stackTrace) {
      print('[StorageFactory] ❌ 初始化失败: $e');
      print('[StorageFactory] 📍 堆栈: $stackTrace');
      rethrow;
    }

    return _instance!;
  }

  static void reset() {
    _instance?.close();
    _instance = null;
  }
}
