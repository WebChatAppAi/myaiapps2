import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../services/secure_storage_service.dart';

class SettingsState {
  final String baseUrl;
  final String apiKey;
  final String selectedModel;
  final String modelType;
  final bool isConnected;
  final String lastConnectionMessage;

  SettingsState({
    this.baseUrl = '',
    this.apiKey = '',
    this.selectedModel = '',
    this.modelType = 'openai',
    this.isConnected = false,
    this.lastConnectionMessage = '',
  });

  SettingsState copyWith({
    String? baseUrl,
    String? apiKey,
    String? selectedModel,
    String? modelType,
    bool? isConnected,
    String? lastConnectionMessage,
  }) {
    return SettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      modelType: modelType ?? this.modelType,
      isConnected: isConnected ?? this.isConnected,
      lastConnectionMessage:
          lastConnectionMessage ?? this.lastConnectionMessage,
    );
  }

  // Check if using a Gemini model based on the stored model type
  bool get isGeminiModel => modelType == 'gemini';
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }
  AIService _aiService = AIService(baseUrl: '', apiKey: '');

  // Getter for AIService
  AIService get aiService => _aiService;

  Future<void> _loadSettings() async {
    try {
      // Migrate data from SharedPreferences to secure storage on first run
      await SecureStorageService.migrateFromSharedPreferences();

      // Load all saved settings from secure storage
      final savedBaseUrl = await SecureStorageService.getBaseUrl() ?? '';
      final savedApiKey = await SecureStorageService.getApiKey() ?? '';
      final savedModel = await SecureStorageService.getSelectedModel() ?? '';
      final savedModelType =
          await SecureStorageService.getModelType() ?? 'openai';
      final isConnected = await SecureStorageService.getIsConnected();

      // Only update state if we have saved values
      if ((savedBaseUrl.isNotEmpty && savedApiKey.isNotEmpty) ||
          savedModelType == 'gemini') {
        state = state.copyWith(
          baseUrl: savedBaseUrl,
          apiKey: savedApiKey,
          selectedModel: savedModel,
          modelType: savedModelType,
          isConnected: isConnected,
        );

        print(
            'Loaded saved settings - BaseURL: $savedBaseUrl, Model: $savedModel, Type: $savedModelType');
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
  Future<void> setSelectedModel(String modelDisplayName) async {
    try {
      // The modelDisplayName could be "alvandefault" or an actual model name.
      // AIService's isGeminiModel handles the mapping internally
      final isGemini = _aiService.isGeminiModel(modelDisplayName);
      final modelType = isGemini ? 'gemini' : 'openai';

      await SecureStorageService.setSelectedModel(modelDisplayName); // Save the display name
      await SecureStorageService.setModelType(modelType);
      
      // Connection status for Gemini is typically assumed true if API key is present.
      // For OpenAI, testConnection would verify.
      bool isConnected = isGemini ? true : state.isConnected; // Preserve OpenAI connection status
      if (isGemini) {
         await SecureStorageService.setIsConnected(true);
      }      state = state.copyWith(
        selectedModel: modelDisplayName, // Store the name shown in UI
        modelType: modelType,
        isConnected: isConnected,
      );
      // Update AIService about the model change so it can set its internal _activeModelType
      _aiService.setModelType(modelDisplayName); 

      print('[SettingsNotifier VERBOSE] Saved selected model (display name): $modelDisplayName, Type: $modelType');
    } catch (e) {
      print('[SettingsNotifier ERROR] Error saving selected model: $e');
    }
  }

  Future<(bool success, String message)> testConnection() async {
    // AIService's testConnection now internally checks _activeModelType which is set by setModelType
    // which in turn uses _getActualModelName and isGeminiModel.
    // So, state.selectedModel (which is the display name) is fine here.
    // The _aiService.isGeminiModel call inside testConnection will use the logic
    // that correctly identifies "alvandefault" via _getActualModelName.    // If the selected model (display name) maps to a Gemini model
    if (_aiService.isGeminiModel(state.selectedModel)) {
      state = state.copyWith(
        isConnected: true, // Assumed true for Gemini if key is okay (checked by AIService)
        lastConnectionMessage: 'Using Gemini model (${state.selectedModel}). API key presence is the main check.',
      );
      // Optionally, AIService's testConnection could do a more specific Gemini check
      return await _aiService.testConnection(); // Let AIService perform its Gemini check
    }

    // OpenAI connection test
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
    // First refresh the Gemini models to get the latest list
    await _aiService.refreshGeminiModels();

    // Then fetch all available models (both Gemini and OpenAI)
    final models = await _aiService.fetchAvailableModels();

    // If models are found, check if we need to update the state
    if (models.isNotEmpty && state.selectedModel.isEmpty) {
      // Select a default model if one isn't already selected
      final defaultModel = models.first;
      await setSelectedModel(defaultModel);
    }

    return models;
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
