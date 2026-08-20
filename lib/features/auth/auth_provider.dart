import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({this.isLoading = false, this.isAuthenticated = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, bool? isAuthenticated, String? error, Map<String, dynamic>? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error, // Can be null
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    checkAuthStatus();
    return AuthState();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userStr = prefs.getString('user_data');
    if (token != null && userStr != null) {
      state = state.copyWith(isAuthenticated: true, user: jsonDecode(userStr));
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.post('/auth/login.php', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['jwt']);
        await prefs.setString('user_data', jsonEncode(data['user']));
        
        state = state.copyWith(isLoading: false, isAuthenticated: true, user: data['user']);
        return true;
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(isLoading: false, error: data['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.post('/auth/register.php', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });

      if (response.statusCode == 201) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(isLoading: false, error: data['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> _saveToken(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_data', jsonEncode(user));
  }

  Future<void> updateToken(String token, Map<String, dynamic> user) async {
    await _saveToken(token, user);
    state = state.copyWith(user: user, isAuthenticated: true);
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
    state = AuthState();
  }
}
