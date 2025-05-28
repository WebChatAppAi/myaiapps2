import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthState {
  final bool isAuthenticated;
  final String? accessKey;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.accessKey,
    this.isLoading = true,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessKey,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessKey: accessKey ?? this.accessKey,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(AppConstants.keyPreferenceKey);

      if (savedKey == AppConstants.validAccessKey) {
        state = state.copyWith(
          isAuthenticated: true,
          accessKey: savedKey,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          accessKey: null,
          isLoading: false,
        );
      }
    } catch (e) {
      print('Error checking auth status: $e');
      state = state.copyWith(
        isAuthenticated: false,
        accessKey: null,
        isLoading: false,
      );
    }
  }

  Future<bool> validateAndSaveKey(String key) async {
    if (key != AppConstants.validAccessKey) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyPreferenceKey, key);

      state = state.copyWith(
        isAuthenticated: true,
        accessKey: key,
      );

      return true;
    } catch (e) {
      print('Error saving access key: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyPreferenceKey);

      state = state.copyWith(
        isAuthenticated: false,
        accessKey: null,
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
