import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Pure server communication class - handles WebSocket connections and messaging
class PomodoroWebSocketServer {
  late StompClient _stompClient;
  bool _connected = false;
  String? _currentToken;
  bool _isConnecting = false; // Prevent multiple connections

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
    // Prevent multiple simultaneous connections
    if (_isConnecting || _connected) {
      print('[WS] Already connecting or connected, skipping...');
      return;
    }

    _isConnecting = true;

    // Get the current auth token
    _currentToken = await _getAuthToken();

    if (_currentToken == null) {
      _errorController.add('No authentication token found');
      _isConnecting = false;
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
          _isConnecting = false;
        },
        onStompError: (frame) {
          print('[WS] STOMP error: ${frame.body}');
          _errorController.add('STOMP error: ${frame.body}');
          _isConnecting = false;
        },
        onDisconnect: (frame) {
          _connected = false;
          _isConnecting = false;
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
    _isConnecting = false;
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

  /// Force stop any running timer on server before starting new one
  Future<void> forceStopTimer() async {
    if (!_connected) return;

    print('[WS] 📤 Force stopping any running timer');
    _stompClient.send(destination: '/app/pomodoro/stop', body: jsonEncode({}));

    // Wait a bit for the stop to process
    await Future.delayed(Duration(milliseconds: 500));
  }

  /// Enhanced start method that handles "already running" scenario
  Future<void> startPomodoroSafe({
    int duration = 60,
    int remainingTime = 60,
    int timerType = 1,
    String mode = "new",
    int type = 1,
    String? description = "Work session",
    bool status = false,
    int step = 0,
  }) async {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    // First, try to stop any existing timer
    await forceStopTimer();

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

    print('[WS] 📤 Starting pomodoro (safe): ${jsonEncode(body)}');
    _send('/app/pomodoro/start', body);
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

  /// Start short break session
  void startShortBreak({
    int? duration,
    int? remainingTime,
    int timerType = 1,
    String mode = "existing",
    int type = 2, // Type 2 for short break
    String? description = "Short break session",
    bool status = false,
    int step = 0,
    int? sequenceId,
  }) async {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    // Stop any running timer first
    await forceStopTimer();

    final body = {
      "timerRequest": {
        "duration": duration ?? 300, // 5 minutes default
        "remainingTime": remainingTime ?? 300,
        "timerType": timerType,
      },
      "sequenceRequest": {
        "mode": mode,
        "type": type,
        "description": description,
        "status": status,
        if (sequenceId != null) "sequenceId": sequenceId,
      },
      "timerSequenceRequest": {"step": step},
    };

    print('[WS] 📤 Starting short break: ${jsonEncode(body)}');
    _send('/app/pomodoro/start', body);
  }

  /// Start long break session
  void startLongBreak({
    int? duration,
    int? remainingTime,
    int timerType = 1,
    String mode = "existing",
    int type = 3, // Type 3 for long break
    String? description = "Long break session",
    bool status = false,
    int step = 0,
    int? sequenceId,
  }) async {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    // Stop any running timer first
    await forceStopTimer();

    final body = {
      "timerRequest": {
        "duration": duration ?? 1500, // 25 minutes default
        "remainingTime": remainingTime ?? 1500,
        "timerType": timerType,
      },
      "sequenceRequest": {
        "mode": mode,
        "type": type,
        "description": description,
        "status": status,
        if (sequenceId != null) "sequenceId": sequenceId,
      },
      "timerSequenceRequest": {"step": step},
    };

    print('[WS] 📤 Starting long break: ${jsonEncode(body)}');
    _send('/app/pomodoro/start', body);
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

  /// Resume short break timer
  void resumeShortBreak({
    required int remainingTime,
    required int timerId,
    required int sequenceId,
  }) {
    timerResume(remainingTime: remainingTime, timerId: timerId, sequenceId: sequenceId);
  }

  /// Resume long break timer
  void resumeLongBreak({
    required int remainingTime,
    required int timerId,
    required int sequenceId,
  }) {
    timerResume(remainingTime: remainingTime, timerId: timerId, sequenceId: sequenceId);
  }

  /// Stop timer
  void timerStop() {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    print('[WS] 📤 Stopping timer');
    _stompClient.send(destination: '/app/pomodoro/stop', body: jsonEncode({}));
  }

  /// Stop short break timer
  void stopShortBreak() {
    timerStop();
  }

  /// Stop long break timer
  void stopLongBreak() {
    timerStop();
  }

  /// Reset timer
  void timerReset({required int timerId}) {
    if (!_connected) {
      _errorController.add('Not connected to server');
      return;
    }

    final payload = {"timerId": timerId};
    print('[WS] 📤 Resetting timer: ${jsonEncode(payload)}');
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
    if (_connected || _isConnecting) {
      _stompClient.deactivate();
      _connected = false;
      _isConnecting = false;
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