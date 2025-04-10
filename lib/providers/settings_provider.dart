import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';
import '../services/secure_storage_service.dart';

class SettingsState {
  final String baseUrl;
  final String apiKey;
  final String selectedModel;
  final bool isConnected;
  final String lastConnectionMessage;

  SettingsState({
    this.baseUrl = '',
    this.apiKey = '',
    this.selectedModel = '',
    this.isConnected = false,
    this.lastConnectionMessage = '',
  });

  SettingsState copyWith({
    String? baseUrl,
    String? apiKey,
    String? selectedModel,
    bool? isConnected,
    String? lastConnectionMessage,
  }) {
    return SettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      isConnected: isConnected ?? this.isConnected,
      lastConnectionMessage:
          lastConnectionMessage ?? this.lastConnectionMessage,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  AIService _aiService = AIService(baseUrl: '', apiKey: '');

  // Add getter for AIService
  AIService get aiService => _aiService;

  static const String _selectedModelKey = 'selected_model';
  static const String _isConnectedKey = 'is_connected';

  Future<void> _loadSettings() async {
    try {
      // Migrate data from SharedPreferences to secure storage on first run
      await SecureStorageService.migrateFromSharedPreferences();

      // Load all saved settings from secure storage
      final savedBaseUrl = await SecureStorageService.getBaseUrl() ?? '';
      final savedApiKey = await SecureStorageService.getApiKey() ?? '';
      final savedModel = await SecureStorageService.getSelectedModel() ?? '';
      final isConnected = await SecureStorageService.getIsConnected();

      // Only update state if we have saved values
      if (savedBaseUrl.isNotEmpty && savedApiKey.isNotEmpty) {
        state = state.copyWith(
          baseUrl: savedBaseUrl,
          apiKey: savedApiKey,
          selectedModel: savedModel,
          isConnected: isConnected,
        );

        print(
            'Loaded saved settings - BaseURL: $savedBaseUrl, Model: $savedModel');
        _updateAIService();
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  void _updateAIService() {
    print(
        'Updating AI Service with baseUrl: ${state.baseUrl}, apiKey: ${state.apiKey}');
    _aiService = AIService(
      baseUrl: state.baseUrl,
      apiKey: state.apiKey,
    );
  }

  Future<void> setBaseUrl(String url) async {
    try {
      await SecureStorageService.setBaseUrl(url);
      state = state.copyWith(
        baseUrl: url,
        isConnected: false,
        lastConnectionMessage: '',
      );
      _updateAIService();
    } catch (e) {
      print('Error saving base URL: $e');
    }
  }

  Future<void> setApiKey(String key) async {
    try {
      await SecureStorageService.setApiKey(key);
      state = state.copyWith(
        apiKey: key,
        isConnected: false,
        lastConnectionMessage: '',
      );
      _updateAIService();
    } catch (e) {
      print('Error saving API key: $e');
    }
  }

  Future<void> setSelectedModel(String model) async {
    try {
      await SecureStorageService.setSelectedModel(model);
      await SecureStorageService.setIsConnected(true);
      state = state.copyWith(
        selectedModel: model,
        isConnected: true,
      );
      print('Saved selected model: $model');
    } catch (e) {
      print('Error saving selected model: $e');
    }
  }

  Future<(bool success, String message)> testConnection() async {
    print(
        'Testing connection with baseUrl: ${state.baseUrl}, apiKey: ${state.apiKey}');
    try {
      if (state.baseUrl.isEmpty || state.apiKey.isEmpty) {
        state = state.copyWith(
          isConnected: false,
          lastConnectionMessage: 'Base URL and API key are required',
        );
        return (false, 'Base URL and API key are required');
      }

      final (success, message) = await _aiService.testConnection();

      // Save connection status
      if (success) {
        await SecureStorageService.setIsConnected(true);
      }

      state = state.copyWith(
        isConnected: success,
        lastConnectionMessage: message,
      );
      return (success, message);
    } catch (e) {
      final message = 'Unexpected error: $e';
      state = state.copyWith(
        isConnected: false,
        lastConnectionMessage: message,
      );
      return (false, message);
    }
  }

  Future<List<String>> fetchAvailableModels() async {
    if (state.baseUrl.isEmpty || state.apiKey.isEmpty) {
      state = state.copyWith(
        lastConnectionMessage: 'Base URL and API key are required',
      );
      return [];
    }

    try {
      final models = await _aiService.fetchAvailableModels();
      if (models.isEmpty) {
        state = state.copyWith(
          lastConnectionMessage: 'No models found or error occurred',
        );
      }
      return models;
    } catch (e) {
      state = state.copyWith(
        lastConnectionMessage: 'Failed to fetch models: $e',
      );
      return [];
    }
  }

  Future<void> clearAllData() async {
    await SecureStorageService.clearAll();
    state = SettingsState();
    _updateAIService();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
