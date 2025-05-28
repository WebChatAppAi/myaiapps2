import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/page_transitions.dart';
import '../chat/chat_list_screen.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generateImage() {
    if (_promptController.text.trim().isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    // Simulate image generation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    });
  }

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
                  // Profile Button (Left)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: Navigate to profile
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.messageBackground.withOpacity(0.5),
                        ),
                        child: Icon(
                          Icons.person_outline,
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
                  SizedBox(width: 40),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Image Generation",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Image Prompt Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  hintText: "Enter your image prompt...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.messageBackground,
                ),
                maxLines: 3,
                style: TextStyle(color: AppColors.textColor),
              ),
            ),

            // Generate Button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Generate Image",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
            ),

            // Preview Area
            Expanded(
              child: Center(
                child: Text(
                  "Generated image will appear here",
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
