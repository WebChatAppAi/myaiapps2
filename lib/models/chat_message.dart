import 'package:flutter/foundation.dart';

enum MessageRole {
  user,
  assistant,
  system,
}

enum MessageStatus {
  sending,
  sent,
  error,
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final String? errorMessage;
  final bool isStreaming;
  final List<String> codeBlocks;
  final Map<String, String> codeLanguages; // Maps code block index to language

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.errorMessage,
    this.isStreaming = false,
    List<String>? codeBlocks,
    Map<String, String>? codeLanguages,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now(),
        codeBlocks = codeBlocks ?? [],
        codeLanguages = codeLanguages ?? {};

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    String? errorMessage,
    bool? isStreaming,
    List<String>? codeBlocks,
    Map<String, String>? codeLanguages,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isStreaming: isStreaming ?? this.isStreaming,
      codeBlocks: codeBlocks ?? this.codeBlocks,
      codeLanguages: codeLanguages ?? this.codeLanguages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.toString(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'codeBlocks': codeBlocks,
      'codeLanguages': codeLanguages,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      codeBlocks: (json['codeBlocks'] as List<dynamic>?)?.cast<String>() ?? [],
      codeLanguages: (json['codeLanguages'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.role == role &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.isStreaming == isStreaming &&
        listEquals(other.codeBlocks, codeBlocks) &&
        mapEquals(other.codeLanguages, codeLanguages);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      role,
      content,
      timestamp,
      status,
      errorMessage,
      isStreaming,
      Object.hashAll(codeBlocks),
      Object.hashAll(codeLanguages.entries),
    );
  }
}
