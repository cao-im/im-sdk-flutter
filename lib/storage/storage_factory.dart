import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';
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
        print('[StorageFactory] ✅ Web 平台: WasmDatabase (IndexedDB/OPFS)');
      } else {
        print('[StorageFactory] ✅ ${_platformLabel()} 平台: NativeDatabase (文件持久化)');
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

  static String _platformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }
}
