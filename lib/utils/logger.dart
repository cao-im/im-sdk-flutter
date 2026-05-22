import 'package:logger/logger.dart' show Logger, Level, PrettyPrinter;

export 'package:logger/logger.dart' show Logger, Level;

class AppLogger {
  static Logger? _instance;

  static Logger get instance {
    _instance ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
    return _instance!;
  }

  static void setLevel(Level level) {
    _instance = null;
    _instance = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: level,
    );
  }
}
