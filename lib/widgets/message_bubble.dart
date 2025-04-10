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

class AIMessageBubble extends StatelessWidget {
  final String message;
  final bool hasCode;
  final String? codeBlock;

  const AIMessageBubble({
    super.key,
    required this.message,
    this.hasCode = false,
    this.codeBlock,
  });

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
                MarkdownBody(
                  data: message,
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

                // Code Block (if any)
                if (hasCode && codeBlock != null) ...[
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
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: codeBlock!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Code copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.copy,
                                        color: AppColors.textColor
                                            .withOpacity(0.7),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Copy',
                                        style: TextStyle(
                                          color: AppColors.textColor
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: HighlightView(
                            codeBlock!,
                            language: 'dart',
                            theme: monokaiSublimeTheme,
                            textStyle: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
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
