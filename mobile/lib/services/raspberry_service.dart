import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class RaspberryPiService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _piIpAddress = "192.168.1.100";
  int _piPort = 8000;

  int _batteryLevel = 95;
  double _temperature = 38.5;
  String _currentExpression = "happy";

  bool get isConnected => _isConnected;
  String get piIpAddress => _piIpAddress;
  int get batteryLevel => _batteryLevel;
  double get temperature => _temperature;
  String get currentExpression => _currentExpression;

  void setIpAddress(String ip) {
    _piIpAddress = ip;
    notifyListeners();
  }

  /// Connect to FastAPI WebSocket / Raspberry Pi sync channel
  Future<void> connectToPi({String? customUrl}) async {
    final String wsUrl = customUrl ?? "ws://$_piIpAddress:$_piPort/ws/mobile";

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data["type"] == "PI_TELEMETRY" || data["type"] == "PI_STATUS_UPDATE") {
        final piData = data["data"] ?? {};
        _isConnected = piData["connected"] ?? true;
        _batteryLevel = piData["battery_level"] ?? _batteryLevel;
        _temperature = (piData["temperature_c"] as num?)?.toDouble() ?? _temperature;
        _currentExpression = piData["expression"] ?? _currentExpression;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error parsing Pi WS message: $e");
    }
  }

  /// Send movement or action to physical Raspberry Pi
  void sendMovement(String movementCommand) {
    if (_channel != null) {
      final payload = jsonEncode({
        "type": "PI_COMMAND",
        "payload": {
          "command": movementCommand,
          "speed": 60,
          "duration_ms": 1500
        }
      });
      _channel!.sink.add(payload);
    }
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
    notifyListeners();
  }
}
