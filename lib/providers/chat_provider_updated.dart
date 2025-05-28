import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import 'settings_provider.dart';
import '../utils/toast_utils.dart';
import '../utils/navigator_key.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isStreaming; // To indicate an active stream
  final String? streamError; // For actual errors from the stream
  final String? currentReasoning; // For AI reasoning text

  ChatState({
    List<ChatMessage>? messages,
    this.isLoading = false,
    this.error,
    this.isStreaming = false,
    this.streamError,
    this.currentReasoning,
  }) : messages = messages ?? [];

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isStreaming,
    String? streamError,
    String? currentReasoning,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error, // General errors
      isStreaming: isStreaming ?? this.isStreaming,
      streamError: streamError, // Stream-specific errors
      currentReasoning: currentReasoning ?? this.currentReasoning,
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
  StreamSubscription? _reasoningSubscription;
  // Add conversation history for AI models
  List<Map<String, String>> _conversationHistory = [];

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _reasoningSubscription?.cancel();
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

  Future<void> sendMessage(String message, String model) async {
    if (message.trim().isEmpty) return;    // Cancel any existing streams
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _reasoningSubscription?.cancel();
    _reasoningSubscription = null;
    String currentReasoningText = '';

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    // Add AI message placeholder
    final aiMessagePlaceholder = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), // Ensure unique ID
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, aiMessagePlaceholder],
      isLoading: true,
      isStreaming: true,
      error: null,
      streamError: null,
      currentReasoning: null,
    );    try {
      final aiService = ref.read(settingsProvider.notifier).aiService;
      
      // Prepare conversation history (excluding the placeholder)
      final history = state.messages
          .where((m) => m.id != aiMessagePlaceholder.id) // Exclude placeholder
          .map((msg) => {
                "role": msg.role.toString().split('.').last,
                "parts": msg.content,
              })
          .toList();      // Subscribe to the reasoning stream
      final reasoningStream = aiService.reasoningStream;
      if (reasoningStream != null) {
        _reasoningSubscription = reasoningStream.listen(
          (reasoningChunk) {
            currentReasoningText += reasoningChunk;
            final updatedMessages = List<ChatMessage>.from(state.messages);
            final aiMessageIndex = updatedMessages.indexWhere((m) => m.id == aiMessagePlaceholder.id);
            if (aiMessageIndex != -1) {
              updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(
                reasoning: currentReasoningText,
              );
              state = state.copyWith(
                messages: updatedMessages,
                currentReasoning: currentReasoningText,
              );
            }
          },
          onError: (error) {
            print('Reasoning stream error: $error');
            // Optionally update state with reasoning stream error
          },
        );
      }

      final responseStream = await aiService.streamChatWithHistory(
        message,
        model,
        history, // Pass history without the current user message, as AIService might add it
      );

      String currentResponseContent = '';
      _streamSubscription = responseStream.listen(
        (chunk) {
          currentResponseContent += chunk;
          final updatedMessages = List<ChatMessage>.from(state.messages);
          final aiMessageIndex = updatedMessages.indexWhere((m) => m.id == aiMessagePlaceholder.id);
          if (aiMessageIndex != -1) {
            updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(
              content: currentResponseContent,
            );
            state = state.copyWith(messages: updatedMessages, isStreaming: true);
          }
        },
        onError: (error) {
          print('Content stream error: $error');
          final updatedMessages = List<ChatMessage>.from(state.messages);
          final aiMessageIndex = updatedMessages.indexWhere((m) => m.id == aiMessagePlaceholder.id);
          if (aiMessageIndex != -1) {
            updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(
              content: currentResponseContent.isEmpty ? 'Error: $error' : currentResponseContent,
              status: MessageStatus.error,
              errorMessage: error.toString(),
              isStreaming: false,
              reasoning: currentReasoningText.isNotEmpty ? currentReasoningText : null,
            );
          }
          state = state.copyWith(
            messages: updatedMessages,
            isLoading: false,
            isStreaming: false,            streamError: error.toString(),
          );
          _reasoningSubscription?.cancel();          ToastUtils.showErrorToast(
            navigatorKey.currentContext,
            'Error: $error',
          );
        },
        onDone: () {
          final updatedMessages = List<ChatMessage>.from(state.messages);
          final aiMessageIndex = updatedMessages.indexWhere((m) => m.id == aiMessagePlaceholder.id);
          if (aiMessageIndex != -1) {
            updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(
              content: currentResponseContent,
              isStreaming: false,
              status: MessageStatus.sent,
              reasoning: currentReasoningText.isNotEmpty ? currentReasoningText : null,
            );
          }

          // Update conversation history with the new messages
          _conversationHistory.add({"role": "user", "parts": message});
          _conversationHistory.add({"role": "model", "parts": currentResponseContent});
          
          state = state.copyWith(
            messages: updatedMessages,            isLoading: false,
            isStreaming: false,
            currentReasoning: null, // Clear reasoning once done
          );
          _reasoningSubscription?.cancel();
          _saveMessages();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Error in sendMessage: $e');
      final updatedMessages = List<ChatMessage>.from(state.messages);
      final aiMessageIndex = updatedMessages.indexWhere((m) => m.id == aiMessagePlaceholder.id);
      if (aiMessageIndex != -1) {
         updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(
            content: 'Failed to send message: $e',
            status: MessageStatus.error,
            errorMessage: e.toString(),
            isStreaming: false,
          );
      } else { // Should not happen if placeholder was added
          final errorAiMessage = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            content: 'Failed to send message: $e',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            status: MessageStatus.error,
            errorMessage: e.toString(),
            isStreaming: false,
          );
          updatedMessages.add(errorAiMessage);
      }
      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        isStreaming: false,        error: e.toString(), // General error
        currentReasoning: null,
      );
      _reasoningSubscription?.cancel();      ToastUtils.showErrorToast(
        navigatorKey.currentContext,
        'Error: ${e.toString()}',
      );
    }
  }

  void clearChat() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
    // Clear conversation history when starting a new chat
    _conversationHistory = [];
    state = ChatState();    // Show info toast
    ToastUtils.showInfoToast(
      navigatorKey.currentContext,
      'New chat started',
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
