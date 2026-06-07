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
