/// 保留消息 ID 的十进制原文。
///
/// Web 上 JSON 数字只能精确表示 2^53 以内的整数，服务端雪花 ID 会在
/// `jsonDecode` 时被改掉。同步游标和去重必须使用原始数字字符串。
class IdLiteral {
  static String? text(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return BigInt.tryParse(trimmed)?.toString();
    }
    if (value is int) return value.toString();
    if (value is num) {
      if (!value.isFinite) return null;
      return value.round().toString();
    }
    final trimmed = value.toString().trim();
    if (trimmed.isEmpty) return null;
    return BigInt.tryParse(trimmed)?.toString();
  }

  static int? asInt(dynamic value) {
    final digits = text(value);
    if (digits == null) return null;
    final exact = int.tryParse(digits);
    if (exact != null) return exact;
    final approx = double.tryParse(digits);
    if (approx == null || !approx.isFinite) return null;
    return approx.round();
  }

  static bool isPositive(String? value) {
    final parsed = value == null ? null : BigInt.tryParse(value);
    return parsed != null && parsed > BigInt.zero;
  }

  static bool greaterThan(String? left, String? right) {
    final a = left == null ? null : BigInt.tryParse(left);
    if (a == null) return false;
    final b = right == null ? null : BigInt.tryParse(right);
    if (b == null) return true;
    return a > b;
  }

  static String? maxOf(Iterable<String?> values) {
    String? bestText;
    BigInt? best;
    for (final value in values) {
      if (value == null || value.isEmpty) continue;
      final parsed = BigInt.tryParse(value);
      if (parsed == null) continue;
      if (best == null || parsed > best) {
        best = parsed;
        bestText = parsed.toString();
      }
    }
    return bestText;
  }
}
