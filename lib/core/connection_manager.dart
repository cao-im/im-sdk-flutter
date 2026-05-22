import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/logger.dart';
import 'connection_status.dart';
import 'heartbeat.dart';

class ConnectionManager {
  static const int _defaultPort = 80;
  static const String _buildSignature = 'CAOIM-2024-80-LOCKED';

  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _serverUrl = '';
  String _token = '';
  int? _customPort;

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  int _heartbeatInterval = 30;
  late HeartbeatManager _heartbeatManager;

  Map<String, dynamic>? _serverPortInfo;

  final Logger _log = AppLogger.instance;

  Stream<ConnectionStatus> get onStatusChanged => _statusController.stream;
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;

  String _enforcePort(String serverUrl) {
    final uri = Uri.parse(serverUrl);
    final port = _customPort ?? (uri.hasPort ? uri.port : _defaultPort);

    if (uri.hasPort && uri.port != _defaultPort && _customPort == null) {
      _log.w('使用非标准端口 ${uri.port}（推荐端口: $_defaultPort）');
      _log.w('这可能导致与服务端配置不兼容');
    }

    return uri.replace(port: port).toString();
  }

  void setCustomPort(int port) {
    _customPort = port;
  }

  Future<void> _validateServerPort(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl);
      final portInfoUrl = uri.replace(
        scheme: uri.scheme == 'wss' ? 'https' : 'http',
        path: '/api/health/port-info',
      ).toString();

      _log.d('正在验证服务端端口配置: $portInfoUrl');

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);

      final request = await httpClient.getUrl(Uri.parse(portInfoUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(await response.transform(utf8.decoder).join());
        final data = responseData['data'] as Map<String, dynamic>;

        _serverPortInfo = data;

        final serverPort = data['port'] as int;
        final expectedPort = data['expectedPort'] as int;
        final isLocked = data['isPortLocked'] as bool;
        final buildSignature = data['buildSignature'] as String?;
        final warning = data['warning'] as String?;

        _log.i('服务端端口信息获取成功');
        _log.i('- 服务端口: $serverPort');
        _log.i('- 预期端口: $expectedPort');
        _log.i('- 端口锁定状态: ${isLocked ? "已锁定" : "已修改"}');

        if (buildSignature != null && buildSignature != _buildSignature) {
          _log.w('构建签名不匹配!');
          _log.w('SDK期望: $_buildSignature');
          _log.w('服务端实际: $buildSignature');
        }

        if (warning != null) {
          _log.w('服务端警告: $warning');
        }

        if (!isLocked || serverPort != _defaultPort) {
          _log.w('服务端端口配置与 SDK 默认值不匹配');
          _log.w('- SDK 默认端口: $_defaultPort');
          _log.w('- 服务端实际端口: $serverPort');
          _log.w('- 服务端预期端口: $expectedPort');
          if (warning != null) {
            _log.w('- 服务端警告: $warning');
          }
          _log.w('将继续连接，但可能出现兼容性问题');
        }

        _log.i('服务端端口验证通过，可以安全连接');
      } else {
        throw Exception(
            '无法获取服务端端口信息 (HTTP ${response.statusCode})');
      }

      httpClient.close();
    } on SocketException catch (e) {
      _log.w('无法连接到服务端进行端口验证: $e');
      _log.w('将尝试直接连接（可能不安全）');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> connect(String serverUrl, String token) async {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }

    _serverUrl = _enforcePort(serverUrl);
    _token = token;

    _updateStatus(ConnectionStatus.connecting);

    try {
      await _validateServerPort(_serverUrl);

      final uri = Uri.parse('$_serverUrl?token=$token');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _updateStatus(ConnectionStatus.connected);

      _heartbeatManager = HeartbeatManager(
        intervalSeconds: _heartbeatInterval,
        onPing: _sendPing,
        onTimeout: () {
          _log.w('心跳超时，连接可能已断开');
          _handleDisconnection();
        },
      );
      _heartbeatManager.start();
      _listenMessages();
    } catch (e) {
      _updateStatus(ConnectionStatus.disconnected);
      rethrow;
    }
  }

  void disconnect() {
    _heartbeatManager.stop();
    _channel?.sink.close();
    _channel = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void sendMessage(Map<String, dynamic> data) {
    if (!isConnected || _channel == null) {
      throw StateError('WebSocket未连接');
    }
    _channel!.sink.add(jsonEncode(data));
  }

  void _listenMessages() {
    _channel?.stream.listen(
      (message) {
        if (message is String) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;

            if (data['type'] == 'port_handshake_result') {
              _handlePortHandshake(data);
              return;
            }

            if (data['type'] == 'pong') {
              _heartbeatManager.onResponseReceived();
              return;
            }

            _messageController.add(data);
          } catch (e) {
            _log.e('消息解析错误', error: e);
          }
        }
      },
      onDone: () {
        _handleDisconnection();
      },
      onError: (error) {
        _handleDisconnection();
      },
    );
  }

  void _handlePortHandshake(Map<String, dynamic> data) {
    final success = data['success'] as bool? ?? false;
    final message = data['message'] as String? ?? '';

    if (!success) {
      _log.e('服务端端口握手失败: $message');
      disconnect();
      throw StateError('端口握手失败: $message');
    }

    _log.i('服务端端口握手成功');
  }

  void _sendPing() {
    if (isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        _log.e('心跳发送失败', error: e);
      }
    }
  }

  void _handleDisconnection() {
    if (_status == ConnectionStatus.connected) {
      _heartbeatManager.stop();
      _updateStatus(ConnectionStatus.disconnected);
    }
  }

  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  Map<String, dynamic>? get serverPortInfo => _serverPortInfo;

  void dispose() {
    disconnect();
    _heartbeatManager.dispose();
    _statusController.close();
    _messageController.close();
  }
}
