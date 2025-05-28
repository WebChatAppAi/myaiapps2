import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/colors.dart';

class UserMessageBubble extends StatelessWidget {
  final String message;
  final bool hasCode;

  const UserMessageBubble({
    super.key,
    required this.message,
    this.hasCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.messageBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SelectableText(
          message,
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class AIMessageBubble extends StatefulWidget {
  final String message;
  final bool hasCode;
  final String? codeBlock;
  final bool isStreaming;
  final String? reasoning;

  const AIMessageBubble({
    super.key,
    required this.message,
    this.hasCode = false,
    this.codeBlock,
    this.isStreaming = false,
    this.reasoning,
  });

  @override
  State<AIMessageBubble> createState() => _AIMessageBubbleState();
}

class _AIMessageBubbleState extends State<AIMessageBubble> {
  bool _showReasoning = false;

  @override
  void didUpdateWidget(AIMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-close reasoning dropdown when streaming is complete
    if (oldWidget.isStreaming && !widget.isStreaming) {
      setState(() {
        _showReasoning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Logo
          Container(
            width: 32,
            height: 32,
            margin: EdgeInsets.only(top: 8, right: 12),
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

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message Text
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.messageBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: widget.message,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 16,
                          ),
                          code: TextStyle(
                            color: AppColors.textColor,
                            backgroundColor: AppColors.inlineCodeBackground,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      if (widget.isStreaming) ...[
                        SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI is thinking...',
                              style: TextStyle(
                                color: AppColors.textColor.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),

                            // Reasoning button during streaming
                            if (widget.reasoning != null &&
                                widget.reasoning!.isNotEmpty) ...[
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showReasoning = !_showReasoning;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.inlineCodeBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Reasoning',
                                        style: TextStyle(
                                          color: AppColors.textColor
                                              .withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Icon(
                                        _showReasoning
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 16,
                                        color: AppColors.textColor
                                            .withOpacity(0.7),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else if (widget.reasoning != null &&
                          widget.reasoning!.isNotEmpty) ...[
                        // Reasoning button when not streaming
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showReasoning = !_showReasoning;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.inlineCodeBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Reasoning',
                                  style: TextStyle(
                                    color: AppColors.textColor.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  _showReasoning
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: AppColors.textColor.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Reasoning Dropdown
                if (_showReasoning && widget.reasoning != null) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(top: 8, bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.codeBackground.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.codeBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AI Reasoning Process',
                              style: TextStyle(
                                color: Colors.amber.shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: AppColors.textColor.withOpacity(0.7),
                                size: 18,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: widget.reasoning!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Reasoning copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SelectableText(
                          widget.reasoning!,
                          style: TextStyle(
                            color: AppColors.textColor.withOpacity(0.85),
                            fontSize: 13,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Code Block (if any)
                if (widget.hasCode && widget.codeBlock != null) ...[
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.codeBackground,
                      border: Border.all(
                        color: AppColors.codeBorder,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: AppColors.textColor.withOpacity(0.7),
                                size: 20,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: widget.codeBlock!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Code copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        HighlightView(
                          widget.codeBlock!,
                          theme: monokaiSublimeTheme,
                          padding: EdgeInsets.zero,
                          textStyle: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
