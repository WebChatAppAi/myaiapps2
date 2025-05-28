import 'package:flutter/foundation.dart';

enum MessageRole {
  user,
  assistant,
}

enum MessageStatus {
  sending,
  sent,
  error,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final List<String> codeBlocks;
  final bool isStreaming;
  final DateTime timestamp;
  final MessageStatus status;
  final String? errorMessage;
  final Map<String, String> codeLanguages; // Maps code block index to language
  final String? reasoning; // Model's reasoning process

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    List<String>? codeBlocks,
    this.isStreaming = false,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.errorMessage,
    Map<String, String>? codeLanguages,
    this.reasoning,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now(),
        codeBlocks = codeBlocks ?? [],
        codeLanguages = codeLanguages ?? {};

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    List<String>? codeBlocks,
    bool? isStreaming,
    DateTime? timestamp,
    MessageStatus? status,
    String? errorMessage,
    Map<String, String>? codeLanguages,
    String? reasoning,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      codeBlocks: codeBlocks ?? this.codeBlocks,
      isStreaming: isStreaming ?? this.isStreaming,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      codeLanguages: codeLanguages ?? this.codeLanguages,
      reasoning: reasoning ?? this.reasoning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.toString(),
      'codeBlocks': codeBlocks,
      'isStreaming': isStreaming,
      'timestamp': timestamp.toIso8601String(),
      'codeLanguages': codeLanguages,
      'reasoning': reasoning,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => MessageRole.user,
      ),
      codeBlocks: (json['codeBlocks'] as List<dynamic>?)?.cast<String>() ?? [],
      isStreaming: json['isStreaming'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      codeLanguages: (json['codeLanguages'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
      reasoning: json['reasoning'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.content == content &&
        other.role == role &&
        other.isStreaming == isStreaming &&
        other.timestamp == timestamp &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.reasoning == reasoning &&
        listEquals(other.codeBlocks, codeBlocks) &&
        mapEquals(other.codeLanguages, codeLanguages);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      content,
      role,
      isStreaming,
      timestamp,
      status,
      errorMessage,
      reasoning,
      Object.hashAll(codeBlocks),
      Object.hashAll(codeLanguages.entries),
    );
  }
}
