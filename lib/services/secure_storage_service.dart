import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Key constants
  static const String _baseUrlKey = 'openai_base_url';
  static const String _apiKeyKey = 'openai_api_key';
  static const String _selectedModelKey = 'selected_model';
  static const String _isConnectedKey = 'is_connected';
  static const String _migratedKey = 'secure_storage_migrated';

  // Secure read methods
  static Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }

  static Future<String?> getBaseUrl() async {
    return await _secureStorage.read(key: _baseUrlKey);
  }

  // Secure write methods
  static Future<void> setApiKey(String value) async {
    await _secureStorage.write(key: _apiKeyKey, value: value);
  }

  static Future<void> setBaseUrl(String value) async {
    await _secureStorage.write(key: _baseUrlKey, value: value);
  }

  // Non-sensitive data still uses SharedPreferences
  static Future<String?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedModelKey);
  }

  static Future<bool> getIsConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isConnectedKey) ?? false;
  }

  static Future<void> setSelectedModel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModelKey, value);
  }

  static Future<void> setIsConnected(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isConnectedKey, value);
  }

  // Migration from SharedPreferences to secure storage
  static Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_migratedKey) ?? false;

    if (alreadyMigrated) {
      return; // Migration already done
    }

    // Migrate API key
    final apiKey = prefs.getString(_apiKeyKey);
    if (apiKey != null && apiKey.isNotEmpty) {
      await setApiKey(apiKey);
      // Clear from SharedPreferences for security
      await prefs.remove(_apiKeyKey);
    }

    // Migrate base URL
    final baseUrl = prefs.getString(_baseUrlKey);
    if (baseUrl != null && baseUrl.isNotEmpty) {
      await setBaseUrl(baseUrl);
      // We can keep this in SharedPreferences as it's not sensitive
    }

    // Mark as migrated
    await prefs.setBool(_migratedKey, true);
  }

  // Clear all secure data
  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
