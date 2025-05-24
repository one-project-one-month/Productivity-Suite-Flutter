import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final String? error;
  final String? token;

  AuthState({this.isAuthenticated = false, this.error, this.token});

  AuthState copyWith({bool? isAuthenticated, String? error, String? token}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> register(
    String name,
    String username,
    String email,
    String password,
    int gender,
  ) async {
    final url = Uri.parse(
      'https://productivity-suite-java.onrender.com/productivity-suite/api/v1/auth/register',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'gender': gender,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(isAuthenticated: true, error: null);
        return true;
      } else {
        state = state.copyWith(error: 'Registration failed: ${response.body}');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'An error occurred: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse(
      'https://productivity-suite-java.onrender.com/productivity-suite/api/v1/auth/login',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['data']?['accessToken'] as String?;
        if (token != null) {
          state = state.copyWith(
            isAuthenticated: true,
            error: null,
            token: token,
          );
          return true;
        }
        state = state.copyWith(error: 'Invalid server response: no token');
        return false;
      } else {
        state = state.copyWith(error: 'Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'An error occurred: $e');
      return false;
    }
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false, error: null, token: null);
  }
}
