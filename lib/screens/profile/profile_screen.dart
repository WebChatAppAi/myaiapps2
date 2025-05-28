import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../theme/colors.dart';
import '../../utils/page_transitions.dart';
import '../chat/chat_list_screen.dart';
import '../settings/settings_screen.dart';
import '../image/image_generation_screen.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message.dart';
import '../landing/landing_page.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userState = ref.read(userProvider);
    _userNameController.text = userState.userName ?? '';
    _emailController.text = userState.email ?? '';
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // TODO: Implement image picker once the package is added
      // For now, we'll just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image picker will be implemented soon'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveUserInfo() async {
    if (_userNameController.text.isNotEmpty) {
      await ref
          .read(userProvider.notifier)
          .updateUserName(_userNameController.text);
    }
    if (_emailController.text.isNotEmpty) {
      await ref.read(userProvider.notifier).updateEmail(_emailController.text);
    }
    setState(() => _isEditing = false);
  }

  void _showGeneratedImages() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.globalBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final userState = ref.watch(userProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Generated Images',
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (userState.generatedImages.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No generated images yet',
                  style: TextStyle(color: AppColors.textColor.withOpacity(0.7)),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: userState.generatedImages.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(userState.generatedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.globalBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final chatState = ref.watch(chatProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (chatState.messages.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No chat history yet',
                  style: TextStyle(color: AppColors.textColor.withOpacity(0.7)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatState.messages[index];
                    return ListTile(
                      title: Text(
                        message.content,
                        style: TextStyle(color: AppColors.textColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        message.role == MessageRole.user ? 'You' : 'AI',
                        style: TextStyle(
                            color: AppColors.textColor.withOpacity(0.7)),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.messageBackground,
        title: Text(
          'Sign Out',
          style: TextStyle(color: AppColors.textColor),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textColor.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      await ref.read(userProvider.notifier).clearUserData();
      if (mounted) {
        AppNavigator.pushReplacement(context, const LandingPage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.globalBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            children: [
              // Custom AppBar with Logo and Buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Left)
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

                    // Center Logo (Navigate to Chat)
                    GestureDetector(
                      onTap: () {
                        AppNavigator.pushReplacement(
                          context,
                          const ChatListScreen(),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'lib/assets/landing/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    // Settings Button (Right)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          AppNavigator.pushModal(
                            context,
                            const SettingsScreen(),
                          );
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.messageBackground.withOpacity(0.5),
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            color: AppColors.textColor.withOpacity(0.7),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile Avatar
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.messageBackground,
                    border: Border.all(
                      color: AppColors.borderColor,
                      width: 2,
                    ),
                  ),
                  child: userState.profilePicturePath != null
                      ? ClipOval(
                          child: Image.file(
                            File(userState.profilePicturePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.textColor.withOpacity(0.7),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // User Name
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _userNameController,
                    style: TextStyle(color: AppColors.textColor),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(
                          color: AppColors.textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                )
              else
                Text(
                  userState.userName ?? 'User Name',
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 16),

              // Email
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _emailController,
                    style: TextStyle(color: AppColors.textColor),
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(
                          color: AppColors.textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveUserInfo(),
                  ),
                )
              else
                Text(
                  userState.email ?? 'user@example.com',
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),

              const SizedBox(height: 24),

              // Edit/Save Button
              ElevatedButton(
                onPressed: _isEditing
                    ? _saveUserInfo
                    : () => setState(() => _isEditing = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.messageBackground.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Edit Profile',
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Profile Options
              _buildProfileOption(Icons.settings, "Settings", () {
                AppNavigator.pushModal(context, const SettingsScreen());
              }),
              _buildProfileOption(
                  Icons.history, "Chat History", _showChatHistory),
              _buildProfileOption(
                  Icons.image, "My Generated Images", _showGeneratedImages),
              _buildProfileOption(Icons.help_outline, "Help & Support", () {
                // TODO: Implement help & support
              }),
              _buildProfileOption(Icons.logout, "Sign Out", _signOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.messageBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.textColor.withOpacity(0.7),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textColor.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
