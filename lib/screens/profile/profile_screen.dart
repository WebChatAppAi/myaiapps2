import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/page_transitions.dart';
import '../chat/chat_list_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.globalBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar with Logo and Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (Left)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: EdgeInsets.all(8),
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
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ChatListScreen(),
                        ),
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
                  SizedBox(width: 40),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Profile Avatar
            Container(
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
              child: Icon(
                Icons.person,
                size: 60,
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),

            SizedBox(height: 16),

            // User Name
            Text(
              "User Name",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            // Email
            Text(
              "user@example.com",
              style: TextStyle(
                color: AppColors.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),

            SizedBox(height: 32),

            // Profile Options
            _buildProfileOption(Icons.settings, "Settings"),
            _buildProfileOption(Icons.history, "Chat History"),
            _buildProfileOption(Icons.image, "My Generated Images"),
            _buildProfileOption(Icons.help_outline, "Help & Support"),
            _buildProfileOption(Icons.logout, "Sign Out"),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
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
