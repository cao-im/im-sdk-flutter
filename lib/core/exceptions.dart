class IMException implements Exception {
  final String message;
  final int code;
  final StackTrace? stackTrace;

  const IMException(this.message, [this.code = -1, this.stackTrace]);

  @override
  String toString() => 'IMException[$code]: $message';

  factory IMException.network(String msg) => IMException(msg, 1001);

  factory IMException.auth(String msg) => IMException(msg, 1002);

  factory IMException.permission(String msg) => IMException(msg, 1003);

  factory IMException.params(String msg) => IMException(msg, 1004);

  factory IMException.notFound(String msg) => IMException(msg, 1005);

  factory IMException.timeout(String msg) => IMException(msg, 1006);

  factory IMException.server(int code, String msg) =>
      IMException(msg, 2000 + code);

  factory IMException.invalidOperation(String msg) => IMException(msg, 3003);
}

class ErrorCode {
  static const int success = 0;
  static const int unknown = -1;
  static const int networkError = 1001;
  static const int authFailed = 1002;
  static const int permissionDenied = 1003;
  static const int invalidParams = 1004;
  static const int notFound = 1005;
  static const int timeout = 1006;
  static const int messageNotFound = 2001;
  static const int conversationNotFound = 2002;
  static const int groupNotFound = 2003;
  static const int userNotFound = 2004;
  static const int alreadyRecalled = 3001;
  static const int recallTimeout = 3002;
  static const int invalidOperation = 3003;
  static const int userNotInGroup = 3004;
}
