import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../widgets/message_bubble.dart';
import '../settings/settings_screen.dart';
import '../image/image_generation_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message.dart';
import '../../utils/page_transitions.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Animation controllers
  late AnimationController _emptyStateAnimController;
  late Animation<double> _fadeInAnimation;

  // Typing animation variables
  String _fullText = "Alvan-AI is waiting for your message...";
  String _currentText = "";
  bool _isTyping = true;
  bool _isFadingOut = false;
  int _charIndex = 0;

  // Auto-scroll variables
  bool _shouldAutoScroll = true;
  bool _isUserScrolling = false;
  int _lastMessageCount = 0;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _emptyStateAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _emptyStateAnimController,
      curve: Curves.easeIn,
    );

    // Start animation
    _emptyStateAnimController.forward();

    // Start typing animation
    _startTypingAnimation();

    // Add scroll listener
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Detect if user is scrolling
    if (_scrollController.position.activity?.isScrolling ?? false) {
      _isUserScrolling = true;

      // Check if user has scrolled up
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final scrollThreshold = maxScroll - 100.0; // 100px threshold

      _shouldAutoScroll = currentScroll >= scrollThreshold;
    } else {
      _isUserScrolling = false;
    }
  }

  void _startTypingAnimation() {
    // Reset animation state
    _charIndex = 0;
    _currentText = "";
    _isTyping = true;
    _isFadingOut = false;

    // Start typing character by character
    _typeNextChar();
  }

  void _typeNextChar() {
    if (!mounted) return;

    setState(() {
      if (_isTyping && _charIndex < _fullText.length) {
        // Add next character
        _currentText = _fullText.substring(0, _charIndex + 1);
        _charIndex++;

        // Schedule next character
        Future.delayed(Duration(milliseconds: 70), _typeNextChar);
      } else if (_isTyping && _charIndex >= _fullText.length) {
        // Text is fully typed, pause before fade out
        _isTyping = false;
        Future.delayed(Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() => _isFadingOut = true);
            // Schedule restart of animation after fade out
            Future.delayed(Duration(milliseconds: 1500), _startTypingAnimation);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _emptyStateAnimController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Check if this is the first message to animate out empty state
    final isFirstMessage = ref.read(chatProvider).messages.isEmpty;
    if (isFirstMessage &&
        _emptyStateAnimController.status != AnimationStatus.dismissed) {
      _emptyStateAnimController.reverse();
    }

    ref.read(chatProvider.notifier).sendMessage(message);
    _messageController.clear();

    // Force auto-scroll when sending a message
    _shouldAutoScroll = true;

    // Scroll to bottom after sending message
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    // Use a more efficient scrolling approach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Track streaming state
    _isStreaming = chatState.isStreaming;

    // Handle auto-scrolling for new messages
    if (chatState.messages.isNotEmpty) {
      final currentMessageCount = chatState.messages.length;

      // Only auto-scroll if:
      // 1. New message was added
      // 2. Auto-scroll is enabled
      // 3. User is not actively scrolling
      // 4. Message is streaming or just completed
      if (currentMessageCount > _lastMessageCount &&
          _shouldAutoScroll &&
          !_isUserScrolling &&
          (chatState.isStreaming ||
              currentMessageCount == _lastMessageCount + 1)) {
        _scrollToBottom();
      }

      _lastMessageCount = currentMessageCount;
    }

    // Ensure proper animation state based on messages
    if (chatState.messages.isEmpty &&
        _emptyStateAnimController.status == AnimationStatus.dismissed) {
      _emptyStateAnimController.forward();
    } else if (!chatState.messages.isEmpty &&
        _emptyStateAnimController.status != AnimationStatus.dismissed) {
      _emptyStateAnimController.reverse();
    }

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
                        AppNavigator.push(
                          context,
                          const ProfileScreen(),
                        );
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

                  // Center Logo with New Chat Button
                  Row(
                    children: [
                      // New Chat Button
                      if (chatState.messages.isNotEmpty)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              ref.read(chatProvider.notifier).clearChat();
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.messageBackground
                                    .withOpacity(0.5),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: AppColors.textColor.withOpacity(0.7),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      if (chatState.messages.isNotEmpty) SizedBox(width: 12),

                      // Logo
                      GestureDetector(
                        onTap: () {
                          AppNavigator.push(
                            context,
                            const ImageGenerationScreen(),
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
                    ],
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
                        padding: EdgeInsets.all(8),
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

            // Chat List (Expandable)
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: chatState.messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          key: const ValueKey<String>('message_list'),
                          controller: _scrollController,
                          itemCount: chatState.messages.length,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(bottom: 16, top: 16),
                          itemBuilder: (context, index) {
                            final message = chatState.messages[index];
                            return KeepAlive(
                              child: message.role == MessageRole.user
                                  ? UserMessageBubble(
                                      key: ValueKey(message.id),
                                      message: message.content,
                                      hasCode: message.codeBlocks.isNotEmpty,
                                    )
                                  : AIMessageBubble(
                                      key: ValueKey(message.id),
                                      message: message.content,
                                      hasCode: message.codeBlocks.isNotEmpty,
                                      codeBlock: message.codeBlocks.isNotEmpty
                                          ? message.codeBlocks.first
                                          : null,
                                      isStreaming: message.isStreaming,
                                      reasoning: message.reasoning,
                                    ),
                            );
                          },
                        ),
                ),
              ),
            ),

            // Error message if any
            if (chatState.error != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.withOpacity(0.1),
                child: Text(
                  chatState.error!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),

            // Message Input
            Container(
              color: AppColors.primaryBackground,
              child: Container(
                margin: EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: AppColors.messageBackground,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text Input
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 12,
                          bottom: MediaQuery.of(context).padding.bottom + 12,
                          top: 12,
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 16,
                          ),
                          minLines: 1,
                          maxLines: 5,
                          cursorColor: Colors.blue,
                          cursorWidth: 2,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: chatState.isStreaming
                                ? 'AI is typing...'
                                : 'Type a message...',
                            hintStyle: TextStyle(
                              color: AppColors.placeholderColor,
                              fontSize: 16,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    ),

                    // Send Button
                    Padding(
                      padding: EdgeInsets.only(
                        right: 12,
                        bottom: MediaQuery.of(context).padding.bottom + 8,
                        top: 8,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: chatState.isLoading || chatState.isStreaming
                              ? null
                              : _sendMessage,
                          child: Container(
                            height: 38,
                            width: 38,
                            alignment: Alignment.center,
                            child: chatState.isLoading || chatState.isStreaming
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.textColor,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: AppColors.textColor,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Center(
        key: const ValueKey<String>('empty_state'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Alvan-AI logo with enhanced glow
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.2),
                    blurRadius: 25,
                    spreadRadius: 15,
                  ),
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'lib/assets/landing/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Animated typing text
            AnimatedOpacity(
              opacity: _isFadingOut ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 1000),
              child: Text(
                _currentText,
                style: TextStyle(
                  color: AppColors.textColor.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom widget to keep list items alive and prevent rebuilding
class KeepAlive extends StatefulWidget {
  final Widget child;

  const KeepAlive({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
