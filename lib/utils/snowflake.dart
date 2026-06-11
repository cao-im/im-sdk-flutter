import 'package:flutter/foundation.dart' show kIsWeb;

/// 雪花算法（Snowflake）ID 生成器
///
/// 生成全局唯一的 64 位整数 ID，用于消息 mid 等需要客户端生成的场景。
/// 结构（64位）：
/// ┌────┬──────────────────┬─────────┬──────────┐
/// │符号 │   时间戳(41位)    │ 节点ID   │ 序列号    │
/// │ 1位 │                  │ (10位)   │ (12位)   │
/// └────┴──────────────────┴─────────┴──────────┘
///
/// - 时间戳：毫秒级，可用约69年（从自定义纪元开始）
/// - 节点ID：支持1024个节点，这里用随机数模拟
/// - 序列号：每毫秒支持4096个ID
///
/// ⚠️ Web端兼容性：
/// JavaScript 的 Number 类型只能精确表示 2^53 以内的整数（MAX_SAFE_INTEGER ≈ 9×10^15），
/// 而标准雪花算法生成的 ID 约 3×10^17，在 Web 上会产生精度丢失。
/// 因此 Web 端使用降级算法，生成值在 [10^14, 2^53) 范围内的唯一 ID。
class SnowflakeIdGenerator {
  /// 自定义纪元：2024-01-01 00:00:00 UTC
  static const int _epoch = 1704067200000;

  /// 各部分位数
  static const int _workerIdBits = 10;
  static const int _sequenceBits = 12;

  /// 最大值
  static const int _maxWorkerId = (1 << _workerIdBits) - 1; // 1023
  static const int _maxSequence = (1 << _sequenceBits) - 1; // 4095

  /// 左移位数
  static const int _workerIdShift = _sequenceBits;
  static const int _timestampShift = _sequenceBits + _workerIdBits;

  final int _workerId;
  int _sequence = 0;
  int _lastTimestamp = -1;

  /// 单例实例
  static final SnowflakeIdGenerator _instance =
      SnowflakeIdGenerator._internal();

  factory SnowflakeIdGenerator() => _instance;

  SnowflakeIdGenerator._internal() : _workerId = _generateWorkerId();

  /// 生成一个全局唯一ID
  int generate() {
    if (kIsWeb) {
      return _generateWebCompatible();
    }
    return _generateNative();
  }

  /// 原生平台（Android/iOS/Desktop）：标准雪花算法，64位整数无精度问题
  int _generateNative() {
    var timestamp = _currentTimestamp();

    if (timestamp == _lastTimestamp) {
      _sequence = (_sequence + 1) & _maxSequence;
      if (_sequence == 0) {
        // 同一毫秒内序列号用完，等到下一毫秒
        timestamp = _waitNextMillis(_lastTimestamp);
      }
    } else {
      _sequence = 0;
    }

    if (timestamp < _lastTimestamp) {
      // 时钟回拨，直接用当前时间戳（不阻塞）
      timestamp = _currentTimestamp();
    }

    _lastTimestamp = timestamp;

    return ((timestamp - _epoch) << _timestampShift) |
        (_workerId << _workerIdShift) |
        _sequence;
  }

  /// Web 平台（Dart→JS）：降级算法，确保结果在 JS 安全整数范围内 (< 2^53)
  ///
  /// 算法：将时间戳压缩到低位，乘以大基数 + 随机偏移
  /// 结果范围：约 [10^14, 8.8×10^15]，满足以下条件：
  ///   1. > 10^14（通过服务端的雪花ID合法性校验）
  ///   2. < 2^53（JS 安全整数上限，不会精度丢失）
  ///   3. 单节点内唯一（同一毫秒内不同序列号产生不同值）
  int _generateWebCompatible() {
    var timestamp = _currentTimestamp();

    if (timestamp == _lastTimestamp) {
      _sequence = (_sequence + 1) & _maxSequence;
      if (_sequence == 0) {
        timestamp = _waitNextMillis(_lastTimestamp);
      }
    } else {
      _sequence = 0;
    }

    if (timestamp < _lastTimestamp) {
      timestamp = _currentTimestamp();
    }

    _lastTimestamp = timestamp;

    // 时间差（毫秒），约 7.7×10^10（2024年起约 2.4 年内）
    final deltaT = timestamp - _epoch;

    // 公式：base + deltaT * scale + workerId * seqScale + sequence
    // base = 10^14（确保通过服务端合法性校验 MIN_VALID_SNOWFLAKE_MID）
    // scale = 100000（放大时间差，保证时间有序）
    // 最终值 ≈ 10^14 + 7.7×10^15 ≈ 7.8×10^15 < 9×10^15 (MAX_SAFE_INTEGER)
    const int base = 100000000000000;       // 10^14
    const int timeScale = 100000;            // 时间放大因子
    const int seqScale = 10000;             // 序列+节点放大因子

    return base +
        (deltaT * timeScale) +
        (_workerId * seqScale) +
        _sequence;
  }

  /// 批量生成ID（用于测试等场景）
  List<int> generateBatch(int count) {
    return List.generate(count, (_) => generate());
  }

  /// 解析ID的各组成部分（用于调试）
  static Map<String, dynamic> parse(int id) {
    final timestamp = ((id >> _timestampShift) & 0x1FFFFFFFFFF) + _epoch;
    final workerId = (id >> _workerIdShift) & _maxWorkerId;
    final sequence = id & _maxSequence;

    return {
      'raw': id,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
      'workerId': workerId,
      'sequence': sequence,
    };
  }

  static int _currentTimestamp() =>
      DateTime.now().millisecondsSinceEpoch;

  static int _generateWorkerId() {
    // 使用随机数作为节点ID（0-1023），实际生产环境可替换为配置值
    return (DateTime.now().microsecondsSinceEpoch ~/ 1000) & _maxWorkerId;
  }

  static int _waitNextMillis(int lastTimestamp) {
    var timestamp = _currentTimestamp();
    while (timestamp <= lastTimestamp) {
      timestamp = _currentTimestamp();
    }
    return timestamp;
  }
}
