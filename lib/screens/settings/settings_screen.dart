import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  List<String> _availableModels = [];
  bool _isLoading = false;
  String? _selectedModel;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Only load models if we have base URL and API key
    if (_baseUrlController.text.isNotEmpty &&
        _apiKeyController.text.isNotEmpty) {
      _loadAvailableModels();
    }
  }

  void _initializeControllers() {
    final settings = ref.read(settingsProvider);
    _baseUrlController.text = settings.baseUrl;
    _apiKeyController.text = settings.apiKey;
    _selectedModel = settings.selectedModel;
    // Set hasUnsavedChanges to false initially
    _hasUnsavedChanges = false;
  }

  Future<void> _loadAvailableModels() async {
    if (_baseUrlController.text.isEmpty || _apiKeyController.text.isEmpty) {
      return;
    }

    final models =
        await ref.read(settingsProvider.notifier).fetchAvailableModels();

    if (mounted) {
      setState(() {
        _availableModels = models;
        if (_selectedModel?.isEmpty ?? true) {
          _selectedModel = models.isNotEmpty ? models.first : null;
          _hasUnsavedChanges = true;
        }
      });
    }
  }

  Future<void> _checkModels() async {
    if (_baseUrlController.text.isEmpty || _apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter both Base URL and API Key',
            style: TextStyle(color: AppColors.textColor),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _availableModels = [];
    });

    try {
      // Save current values first
      await ref
          .read(settingsProvider.notifier)
          .setBaseUrl(_baseUrlController.text);
      await ref
          .read(settingsProvider.notifier)
          .setApiKey(_apiKeyController.text);

      // Test connection
      final (success, message) =
          await ref.read(settingsProvider.notifier).testConnection();

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connection failed: $message',
                style: TextStyle(color: AppColors.textColor),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // If connection is successful, fetch models
      final models =
          await ref.read(settingsProvider.notifier).fetchAvailableModels();

      if (mounted) {
        setState(() {
          _availableModels = models;
          if (models.isNotEmpty) {
            if (_selectedModel == null || !models.contains(_selectedModel)) {
              _selectedModel = models.first;
              _hasUnsavedChanges = true;
            }
          }
        });

        // Show appropriate message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              models.isEmpty
                  ? 'No models available'
                  : 'Successfully fetched ${models.length} models',
              style: TextStyle(color: AppColors.textColor),
            ),
            backgroundColor: models.isEmpty ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error checking models: $e',
              style: TextStyle(color: AppColors.textColor),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_hasUnsavedChanges) return;

    if (_baseUrlController.text.isEmpty || _apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter both Base URL and API Key',
            style: TextStyle(color: AppColors.textColor),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Save base URL and API key
      await ref
          .read(settingsProvider.notifier)
          .setBaseUrl(_baseUrlController.text);
      await ref
          .read(settingsProvider.notifier)
          .setApiKey(_apiKeyController.text);

      // Save selected model if available
      if (_selectedModel != null && _selectedModel!.isNotEmpty) {
        await ref
            .read(settingsProvider.notifier)
            .setSelectedModel(_selectedModel!);
      }

      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings saved successfully',
              style: TextStyle(color: AppColors.textColor),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.globalBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Settings Header with Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.messageBackground.withOpacity(0.5),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.textColor.withOpacity(0.7),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Settings Title
                  Text(
                    'Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
                  const Spacer(),
                  // Save Button
                  if (_hasUnsavedChanges)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _saveSettings,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentBlue.withOpacity(0.2),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.accentBlue,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.save,
                                  color: AppColors.accentBlue,
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Settings Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Version Info Section
                  _buildSection(
                    title: 'App Info',
                    children: [
                      _buildInfoTile(
                        'Version',
                        AppConstants.appVersion,
                        icon: Icons.info_outline,
                      ),
                    ],
                  ),

                  // OpenAI Configuration Section
                  _buildSection(
                    title: 'API Configuration',
                    children: [
                      _buildInputTile(
                        'Base URL',
                        'Enter your API endpoint (e.g., https://api.openai.com)',
                        controller: _baseUrlController,
                        icon: Icons.link,
                        onChanged: (value) {
                          setState(() => _hasUnsavedChanges = true);
                        },
                      ),
                      _buildInputTile(
                        'API Key',
                        'Enter your API key',
                        controller: _apiKeyController,
                        icon: Icons.key,
                        isSecret: true,
                        onChanged: (value) {
                          setState(() => _hasUnsavedChanges = true);
                        },
                      ),
                      _buildActionButton(
                        'Check Models',
                        icon: _isLoading ? null : Icons.refresh,
                        onPressed: _isLoading ? () {} : _checkModels,
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.accentBlue,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (settings.lastConnectionMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            settings.lastConnectionMessage,
                            style: TextStyle(
                              color: settings.isConnected
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Model Selection Section
                  if (_availableModels.isNotEmpty) ...[
                    _buildSection(
                      title: 'Model Selection',
                      children: [
                        _buildDropdownTile(
                          'AI Model',
                          'Select a Model',
                          icon: Icons.auto_awesome,
                          value: _selectedModel ?? '',
                          items: _availableModels,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedModel = value;
                                _hasUnsavedChanges = true;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],

                  // Data Management Section
                  _buildSection(
                    title: 'Data Management',
                    children: [
                      _buildActionButton(
                        'Clear All Data',
                        icon: Icons.delete_outline,
                        isDestructive: true,
                        onPressed: _clearAllData,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.messageBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: AppColors.textColor.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textColor.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTile(
    String title,
    String hint, {
    required TextEditingController controller,
    IconData? icon,
    bool isSecret = false,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.textColor.withOpacity(0.7),
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isSecret,
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.placeholderColor,
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.borderColor.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.borderColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.accentBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.primaryBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String hint, {
    IconData? icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.textColor.withOpacity(0.7),
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderColor.withOpacity(0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text(
                  hint,
                  style: TextStyle(
                    color: AppColors.placeholderColor,
                    fontSize: 16,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textColor.withOpacity(0.7),
                ),
                dropdownColor: AppColors.primaryBackground,
                items: items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title, {
    IconData? icon,
    bool isDestructive = false,
    required VoidCallback onPressed,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive
              ? Colors.red.withOpacity(0.1)
              : AppColors.accentBlue.withOpacity(0.1),
          foregroundColor: isDestructive ? Colors.red : AppColors.accentBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: child ??
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.messageBackground,
        title: Text(
          'Clear All Data',
          style: TextStyle(color: AppColors.textColor),
        ),
        content: Text(
          'Are you sure you want to clear all settings? This action cannot be undone.',
          style: TextStyle(color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).clearAllData();
      _initializeControllers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All data cleared successfully',
              style: TextStyle(color: AppColors.textColor),
            ),
            backgroundColor: AppColors.messageBackground,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
