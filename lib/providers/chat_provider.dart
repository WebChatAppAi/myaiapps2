import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import 'settings_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isStreaming;
  final String? streamError;

  ChatState({
    List<ChatMessage>? messages,
    this.isLoading = false,
    this.error,
    this.isStreaming = false,
    this.streamError,
  }) : messages = messages ?? [];

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isStreaming,
    String? streamError,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isStreaming: isStreaming ?? this.isStreaming,
      streamError: streamError,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this.ref) : super(ChatState()) {
    _loadMessages();
  }

  final Ref ref;
  static const String _messagesKey = 'chat_messages';
  StreamSubscription? _streamSubscription;

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList(_messagesKey);
      if (messagesJson != null) {
        final messages = messagesJson
            .map((json) => ChatMessage.fromJson(jsonDecode(json)))
            .toList();
        state = state.copyWith(messages: messages);
      }
    } catch (e) {
      print('Error loading messages: $e');
      state = state.copyWith(error: 'Failed to load messages: $e');
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson =
          state.messages.map((msg) => jsonEncode(msg.toJson())).toList();
      await prefs.setStringList(_messagesKey, messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
      state = state.copyWith(error: 'Failed to save messages: $e');
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final settings = ref.read(settingsProvider);
    if (settings.baseUrl.isEmpty ||
        settings.apiKey.isEmpty ||
        settings.selectedModel.isEmpty) {
      state = state.copyWith(
        error: 'Please configure API settings and select a model first',
      );
      return;
    }

    // Cancel any existing stream
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    // Add user message
    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: content,
    );

    // Add AI message placeholder
    final aiMessage = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, aiMessage],
      isLoading: true,
      isStreaming: true,
      error: null,
      streamError: null,
    );

    try {
      final aiService = ref.read(settingsProvider.notifier).aiService;
      final stream =
          await aiService.streamChat(content, settings.selectedModel);

      String responseContent = '';

      _streamSubscription = stream.listen(
        (chunk) {
          responseContent += chunk;

          // Update AI message with current content
          final updatedMessages = [...state.messages];
          updatedMessages[updatedMessages.length - 1] = aiMessage.copyWith(
            content: responseContent,
          );

          state = state.copyWith(
            messages: updatedMessages,
            isStreaming: true,
          );
        },
        onError: (error) {
          print('Stream error: $error');
          final updatedMessages = [...state.messages];
          updatedMessages[updatedMessages.length - 1] = aiMessage.copyWith(
            content:
                responseContent.isEmpty ? 'Error: $error' : responseContent,
            status: MessageStatus.error,
            errorMessage: error.toString(),
            isStreaming: false,
          );

          state = state.copyWith(
            messages: updatedMessages,
            isLoading: false,
            isStreaming: false,
            streamError: error.toString(),
          );
        },
        onDone: () {
          final updatedMessages = [...state.messages];
          updatedMessages[updatedMessages.length - 1] = aiMessage.copyWith(
            content: responseContent,
            isStreaming: false,
            status: MessageStatus.sent,
          );

          state = state.copyWith(
            messages: updatedMessages,
            isLoading: false,
            isStreaming: false,
          );

          _saveMessages();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Error sending message: $e');
      final updatedMessages = [...state.messages];
      updatedMessages[updatedMessages.length - 1] = aiMessage.copyWith(
        content: 'Failed to send message: $e',
        status: MessageStatus.error,
        errorMessage: e.toString(),
        isStreaming: false,
      );

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        isStreaming: false,
        error: e.toString(),
      );
    }
  }

  void clearChat() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
    state = ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
