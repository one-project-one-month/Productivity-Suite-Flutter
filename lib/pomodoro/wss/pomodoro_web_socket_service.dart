import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Pure server communication class - handles WebSocket connections and messaging
class PomodoroWebSocketServer {
  late StompClient _stompClient;
  bool _connected = false;
  String? _currentToken;

  // Streams for state updates
  final StreamController<bool> _connectionController =
  StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController =
  StreamController<String>.broadcast();

  // Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _connected;

  /// Get the stored auth token
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('[WS] Error getting auth token: $e');
      return null;
    }
  }

  /// Initialize and connect to WebSocket
  void connect() async {
    // Get the current auth token
    _currentToken = await _getAuthToken();

    if (_currentToken == null) {
      _errorController.add('No authentication token found');
      return;
    }

    const String wssUrl = "wss://productivity-suite-java.onrender.com/productivity-suite/api/v1/auth/ws";

    _stompClient = StompClient(
      config: StompConfig(
        url: wssUrl,
        onConnect: _onConnect,
        beforeConnect: () async {
          print('[WS] Waiting to connect...');
          await Future.delayed(Duration(milliseconds: 200));
          print('[WS] Connecting with token: ${_currentToken?.substring(0, 20)}...');
        },
        onWebSocketError: (error) {
          print('[WS] WebSocket error: $error');
          _errorController.add('WebSocket error: $error');
        },
        onStompError: (frame) {
          print('[WS] STOMP error: ${frame.body}');
          _errorController.add('STOMP error: ${frame.body}');
        },
        onDisconnect: (frame) {
          _connected = false;
          _connectionController.add(false);
          print('[WS] Disconnected');
        },
        onDebugMessage: (msg) => print('[WS DEBUG] $msg'),
        stompConnectHeaders: _authHeaders(),
        webSocketConnectHeaders: _authHeaders(),
        heartbeatOutgoing: Duration(seconds: 10),
        heartbeatIncoming: Duration(seconds: 10),
        reconnectDelay: Duration(seconds: 5),
      ),
    );

    _stompClient.activate();
  }

  /// Authentication headers for WebSocket connection using dynamic token
  Map<String, String> _authHeaders() {
    return {
      'Authorization': 'Bearer ${_currentToken ?? ''}',
      'content-type': 'application/json',
    };
  }

  /// Handle successful connection
  void _onConnect(StompFrame frame) {
    _connected = true;
    _connectionController.add(true);
    print('[WS] ✅ Connected with dynamic token');

    // Subscribe to personal queue
    _stompClient.subscribe(
      destination: '/user/queue/pomodoro',
      callback: (frame) {
        if (_connected && frame.body != null) {
          print('[WS] 📩 Message received: ${frame.body}');
          try {
            final jsonData = jsonDecode(frame.body!);
            // Handle the expected response format
            if (jsonData is Map<String, dynamic>) {
              _messageController.add(jsonData);
            }
          } catch (e) {
            print('[WS] Error parsing message: $e');
            _errorController.add('Error parsing message: $e');
          }
        }
      },
    );
  }

  /// Reconnect with updated token (call this after login)
  Future<void> reconnectWithNewToken() async {
    if (_connected) {
      disconnect();
    }
    await Future.delayed(Duration(milliseconds: 500));
    connect();
  }

  /// Send start pomodoro request
  void startPomodoro({
    int duration = 60,
    int remainingTime = 60,
    int timerType = 1,
    String mode = "new",
    int type = 1,
    String? description = "Work session",
    bool status = false,
    int step = 0,
  }) {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    final body = {
      "timerRequest": {
        "duration": duration,
        "remainingTime": remainingTime,
        "timerType": timerType,
      },
      "sequenceRequest": {
        "mode": mode,
        "type": type,
        "description": description,
        "status": status,
      },
      "timerSequenceRequest": {"step": step},
    };

    _send('/app/pomodoro/start', body);
  }

  /// Start existing pomodoro session
  void startExistingPomodoro({
    required int duration,
    required int remainingTime,
    required int timerType,
    String mode = 'existing',
    required int sequenceId,
  }) {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    final payload = {
      "timerRequest": {
        "duration": duration,
        "remainingTime": remainingTime,
        "timerType": timerType,
      },
      "sequenceRequest": {"mode": mode, "sequenceId": sequenceId},
    };

    _send('/app/pomodoro/start', payload);
  }

  /// Resume timer
  void timerResume({
    required int remainingTime,
    required int timerId,
    required int sequenceId,
  }) {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    final payload = {
      "remainingTime": remainingTime,
      "timerId": timerId,
      "sequenceId": sequenceId,
    };

    print('[WS] 📤 Sending to /app/pomodoro/resume: ${jsonEncode(payload)}');
    _send('/app/pomodoro/resume', payload);
  }

  /// Stop timer
  void timerStop() {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    _stompClient.send(destination: '/app/pomodoro/stop', body: jsonEncode({}));
  }

  /// Reset timer
  void timerReset({required int timerId}) {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    final payload = {"timerId": timerId};

    _send('/app/pomodoro/reset', payload);
  }

  /// Generic send method
  void _send(String destination, Map<String, dynamic> body) {
    print('[WS] 📤 Sending to $destination: ${jsonEncode(body)}');
    _stompClient.send(destination: destination, body: jsonEncode(body));
  }

  /// Send custom message to any destination
  void sendMessage(String destination, Map<String, dynamic> body) {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }
    _send(destination, body);
  }

  /// Disconnect from server
  void disconnect() {
    if (_connected) {
      _stompClient.deactivate();
      _connected = false;
      _connectionController.add(false);
      print('[WS] 🔌 Disconnected');
    }
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
    _errorController.close();
  }
}