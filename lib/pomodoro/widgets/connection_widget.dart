import 'package:flutter/material.dart';
import 'package:productivity_suite_flutter/pomodoro/models/pomodoro_state_model.dart';

class ConnectionWidget extends StatelessWidget {
  const ConnectionWidget({super.key, required this.pomodoroState});
  final PomodoroState pomodoroState;

  @override
  Widget build(BuildContext context) {
    return _buildConnectionStatus(pomodoroState);
  }
}

Widget _buildConnectionStatus(state) {
  IconData icon;
  Color color;
  String text;

  switch (state.connectionState) {
    case PomodoroConnectionState.connected:
      icon = Icons.wifi;
      color = Colors.green;
      text = 'Connected';
      break;
    case PomodoroConnectionState.connecting:
      icon = Icons.wifi_off;
      color = Colors.orange;
      text = 'Connecting...';
      break;
    case PomodoroConnectionState.error:
      icon = Icons.error;
      color = Colors.red;
      text = 'Connection Error';
      break;
    default:
      icon = Icons.wifi_off;
      color = Colors.grey;
      text = 'Disconnected';
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: color),
      SizedBox(width: 8),
      Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    ],
  );
}
