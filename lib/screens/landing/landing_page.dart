import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import 'key_input_widget.dart';
import '../chat/chat_list_screen.dart';
import '../../providers/auth_provider.dart';
import '../../utils/page_transitions.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _accessKeyController = TextEditingController();
  bool _isLoading = false;
  bool _showKeyInput = false;
  late AnimationController _animationController;
  late Animation<double> _floatingAnimation;
  final List<Color> _colors = [
    const Color(0xFF101010),
    const Color(0xFF1A1A1A),
    const Color(0xFF202020),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Create a floating animation for the logo
    _floatingAnimation = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _accessKeyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _validateAccessKey(String key) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isValid =
          await ref.read(authProvider.notifier).validateAndSaveKey(key);

      if (!mounted) return;

      if (isValid) {
        AppNavigator.pushReplacement(
          context,
          const ChatListScreen(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid access key. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height),
                painter: AnimatedBackgroundPainter(
                  animation: _animationController,
                  colors: _colors,
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Floating Logo Animation
                      AnimatedBuilder(
                        animation: _floatingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnimation.value),
                            child: child!,
                          );
                        },
                        child: FadeInDown(
                          duration: AppConstants.longAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'lib/assets/landing/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Error loading logo: $error');
                                  return Container(
                                    color: Colors.blue.withOpacity(0.1),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.white54,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Welcome Text with Shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.white70,
                        highlightColor: Colors.white,
                        period: Duration(seconds: 3),
                        child: FadeInDown(
                          delay: Duration(milliseconds: 200),
                          duration: AppConstants.longAnimation,
                          child: Text(
                            'Welcome to',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),

                      // App Name with Gradient
                      FadeInDown(
                        delay: Duration(milliseconds: 400),
                        duration: AppConstants.longAnimation,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.blue.shade300,
                              Colors.blue.shade600,
                              Colors.blue.shade900,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            AppConstants.appName,
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 48),

                      // Key Input Section with Glass Effect
                      if (!_showKeyInput)
                        FadeInUp(
                          duration: AppConstants.mediumAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ColorFilter.mode(
                                  Colors.white.withOpacity(0.1),
                                  BlendMode.overlay,
                                ),
                                child: ElevatedButton(
                                  onPressed: () =>
                                      setState(() => _showKeyInput = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    'Enter Access Key',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        FadeInUp(
                          duration: AppConstants.mediumAnimation,
                          child: KeyInputWidget(
                            onKeySubmitted: (key) => _validateAccessKey(key),
                            isLoading: _isLoading,
                          ),
                        ),

                      // Version Info with Fade
                      Padding(
                        padding: const EdgeInsets.only(top: 48.0),
                        child: FadeInUp(
                          delay: Duration(milliseconds: 800),
                          duration: AppConstants.longAnimation,
                          child: Text(
                            'Version ${AppConstants.appVersion}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;

  AnimatedBackgroundPainter({
    required this.animation,
    required this.colors,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final path = Path();

    for (var i = 0; i < 3; i++) {
      final offset = animation.value * 2 * pi + (i * pi / 1.5);
      paint.color = colors[i].withOpacity(0.5);

      path.reset();
      path.moveTo(0, size.height * 0.5);

      for (var x = 0.0; x <= size.width; x += 1) {
        final y = sin(x * 0.01 + offset) * 50 + size.height * 0.5;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(AnimatedBackgroundPainter oldDelegate) => true;
}
