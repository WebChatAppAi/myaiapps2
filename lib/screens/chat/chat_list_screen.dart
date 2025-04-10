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

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(message);
    _messageController.clear();

    // Scroll to bottom after sending message
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Auto-scroll when new messages arrive
    if (chatState.messages.isNotEmpty) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
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

                  // Center Logo
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
                child: chatState.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
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
                                  ),
                          );
                        },
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
                            hintText: 'Type a message...',
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
                          onTap: chatState.isLoading ? null : _sendMessage,
                          child: Container(
                            height: 38,
                            width: 38,
                            alignment: Alignment.center,
                            child: chatState.isLoading
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textColor.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: AppColors.textColor.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a conversation to begin',
            style: TextStyle(
              color: AppColors.textColor.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
