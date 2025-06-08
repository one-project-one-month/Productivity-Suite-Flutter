import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../pomodoro/notifiers/pomodoro_state_notifier.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class ValidationError {
  final String field;
  final String message;

  ValidationError({required this.field, required this.message});

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final String? generalError;
  final List<ValidationError> validationErrors;
  final bool isLoading;
  final String? token;
  final bool isInitialized; // Add this to track if auth state has been initialized

  AuthState({
    this.isAuthenticated = false,
    this.generalError,
    this.validationErrors = const [],
    this.isLoading = false,
    this.token,
    this.isInitialized = false, // Add this
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? generalError,
    List<ValidationError>? validationErrors,
    bool? isLoading,
    String? token,
    bool? isInitialized,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      generalError: generalError ?? this.generalError,
      validationErrors: validationErrors ?? this.validationErrors,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  String? getFieldError(String fieldName) {
    final error = validationErrors.where((e) => e.field == fieldName).toList();
    if (error.isNotEmpty) {
      return error.map((e) => e.message).join('\n');
    }
    return null;
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  late Ref _ref;
  // Update constructor to accept Ref
  AuthNotifier(this._ref) : super(AuthState()) {
    _initializeAuth();
  }


  // Initialize auth state by checking for stored token
  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_tokenKey);
      final userEmail = prefs.getString(_userEmailKey);

      print('Initializing auth... Token exists: ${storedToken != null}');

      if (storedToken != null && storedToken.isNotEmpty) {
        // For now, trust the stored token without verification
        // You can add verification later when you have the proper endpoint
        state = state.copyWith(
          isAuthenticated: true,
          token: storedToken,
          isInitialized: true,
        );
        print('User auto-logged in with stored token');
      } else {
        print('No stored token found');
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      print('Error initializing auth: $e');
      state = state.copyWith(isInitialized: true);
    }
  }

  // Verify if token is still valid - simplified version
  Future<bool> _verifyToken(String token) async {
    try {
      // For now, just assume the token is valid if it exists
      // You can implement proper token verification later when you have the endpoint
      return token.isNotEmpty;

      // Uncomment and modify this when you have a proper token verification endpoint
      /*
      final url = Uri.parse(
        'https://productivity-suite-java.onrender.com/productivity-suite/api/v1/auth/verify',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 5)); // Add timeout

      return response.statusCode == 200;
      */
    } catch (e) {
      print('Error verifying token: $e');
      return false;
    }
  }

  // Store token and user info
  Future<void> _storeAuth(String token, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userEmailKey, email);
      print('Token stored successfully');
    } catch (e) {
      print('Error storing auth: $e');
    }
  }

  // Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userEmailKey);
      print('Stored auth data cleared');
    } catch (e) {
      print('Error clearing stored auth: $e');
    }
  }

  Future<bool> register(
      String name,
      String username,
      String email,
      String password,
      int gender,
      ) async {
    state = state.copyWith(isLoading: true);

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
        state = state.copyWith(isAuthenticated: true, isLoading: false);
        return true;
      } else {
        //parse the error response
        try {
          final responseData = jsonDecode(response.body);

          if (responseData is List) {
            List<ValidationError> errors = [];
            for (var error in responseData) {
              if (error is Map<String, dynamic> &&
                  error.containsKey('field') &&
                  error.containsKey('message')) {
                errors.add(ValidationError.fromJson(error));
              }
            }

            if (errors.isNotEmpty) {
              state = state.copyWith(
                validationErrors: errors,
                isLoading: false,
              );
              return false;
            }
          }
          // Handle "Email is already in use" or "Username is already in use"
          else if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('message')) {
              String message = responseData['message'];
              if (message.contains('Email is already in use')) {
                state = state.copyWith(
                  validationErrors: [
                    ValidationError(
                      field: 'email',
                      message: 'Email is already in use',
                    ),
                  ],
                  isLoading: false,
                );
              } else if (message.contains('Username is already in use')) {
                state = state.copyWith(
                  validationErrors: [
                    ValidationError(
                      field: 'username',
                      message: 'Username is already in use',
                    ),
                  ],
                  isLoading: false,
                );
              } else {
                state = state.copyWith(
                  generalError: 'Registration failed: $message',
                  isLoading: false,
                );
              }
              return false;
            }
          }

          //Default error handling if we couldn't parse specific errors
          state = state.copyWith(
            generalError: 'Registration failed: ${response.body}',
            isLoading: false,
          );
          return false;
        } catch (e) {
          //can't parse the JSON, just use the raw response
          state = state.copyWith(
            generalError: 'Registration failed: ${response.body}',
            isLoading: false,
          );
          return false;
        }
      }
    } catch (e) {
      state = state.copyWith(
        generalError: 'Network error: $e',
        isLoading: false,
      );
      return false;
    }
  }


  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

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
          // Store the token and email
          await _storeAuth(token, email);

          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            token: token,
          );

          // Notify Pomodoro to reconnect with new token
          try {
            final pomodoroNotifier = _ref.read(pomodoroNotifierProvider.notifier);
            await pomodoroNotifier.reconnectAfterLogin();
            print('Pomodoro WebSocket reconnected with new token');
          } catch (e) {
            print('Failed to reconnect Pomodoro WebSocket: $e');
          }

          print('Login successful, token stored');
          return true;
        }

        state = state.copyWith(
          generalError: 'Invalid server response: no token',
          isLoading: false,
        );
        return false;
      } else {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('message')) {
            state = state.copyWith(
              generalError: responseData['message'],
              isLoading: false,
            );
          } else {
            state = state.copyWith(
              generalError: 'Login failed: ${response.body}',
              isLoading: false,
            );
          }
        } catch (e) {
          state = state.copyWith(
            generalError: 'Login failed: ${response.body}',
            isLoading: false,
          );
        }
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        generalError: 'Network error: $e',
        isLoading: false,
      );
      return false;
    }
  }

  void clearErrors() {
    state = state.copyWith(generalError: null, validationErrors: []);
  }

  Future<void> logout() async {
    // Clear stored authentication data
    await _clearStoredAuth();

    state = AuthState(isInitialized: true);
    print('User logged out, stored data cleared');
  }

  // Get stored token
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting stored token: $e');
      return null;
    }
  }

}