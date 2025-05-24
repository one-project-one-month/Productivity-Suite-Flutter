import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class ValidationError{
  final String field;
  final String message;

  ValidationError({
    required this.field,
    required this. message
  });

  factory ValidationError.fromJson(Map<String, dynamic> json){
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

  AuthState({
    this.isAuthenticated = false,
    this.generalError,
    this.validationErrors= const[],
    this.isLoading = false,
  });

  AuthState copyWith({bool? isAuthenticated, String? generalError, List<ValidationError>? validationErrors, bool? isLoading}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      generalError: generalError ?? generalError,
      validationErrors: validationErrors?? this.validationErrors,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  String? getFieldError(String fieldName){
    final error = validationErrors.where((e) => e.field == fieldName).toList();
    if (error.isNotEmpty){
      return error.map((e) => e.message).join('\n');
    }
    return null;
  }
  // bool hasErrors(){
  //   return generalError != null || validationErrors.isNotEmpty;
  // }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> register(String name, String username, String email, String password, int gender) async {
    state = state.copyWith(isLoading: true, generalError: null, validationErrors: []);

    final url = Uri.parse('https://productivity-suite-java.onrender.com/productivity-suite/api/v1/auth/register');
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
              state = state.copyWith(validationErrors: errors, isLoading: false);
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
                      ValidationError(field: 'email', message: 'Email is already in use')
                    ],
                    isLoading: false
                );
              } else if (message.contains('Username is already in use')) {
                state = state.copyWith(
                    validationErrors: [
                      ValidationError(field: 'username', message: 'Username is already in use')
                    ],
                    isLoading: false
                );
              } else {
                state = state.copyWith(generalError: 'Registration failed: $message', isLoading: false);
              }
              return false;
            }
          }

          //Default error handling if we couldn't parse specific errors
          state = state.copyWith(
              generalError: 'Registration failed: ${response.body}',
              isLoading: false
          );
          return false;
        } catch (e) {
          //can't parse the JSON, just use the raw response
          state = state.copyWith(
              generalError: 'Registration failed: ${response.body}',
              isLoading: false
          );
          return false;
        }
      }
    } catch (e) {
      state = state.copyWith(
          generalError: 'Network error: $e',
          isLoading: false
      );
      return false;
    }
  }


  Future<bool> login(String email, String password) async {
    final url = Uri.parse('https://productivity-suite-java.onrender.com/productivity-suite/api/v1/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        state = state.copyWith(isAuthenticated: true, isLoading: false);
        return true;
      } else {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
            state = state.copyWith(
                generalError: responseData['message'],
                isLoading: false
            );
          } else {
            state = state.copyWith(
                generalError: 'Login failed: ${response.body}',
                isLoading: false
            );
          }
        } catch (e) {
          state = state.copyWith(
              generalError: 'Login failed: ${response.body}',
              isLoading: false
          );
        }
        return false;
      }
    } catch (e) {
      state = state.copyWith(
          generalError: 'Network error: $e',
          isLoading: false
      );
      return false;
    }
  }

  void clearErrors() {
    state = state.copyWith(generalError: null, validationErrors: []);
  }
  void logout() {
    state =AuthState();
  }
}