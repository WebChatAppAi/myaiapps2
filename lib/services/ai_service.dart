import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

enum AIModelType {
  openAI,
  gemini,
}

class AIService {
  late final Dio _dio;
  String baseUrl;
  String apiKey;
  AIModelType _activeModelType = AIModelType.gemini; // Default to Gemini

  // Gemini related properties
  GenerativeModel? _geminiModel;
  ChatSession? _chatSession;
  String? _lastInitializedActualModelName; // To track the model used for _geminiModel
  List<String> _availableGeminiModels = [];
  StreamController<String>? _reasoningStreamController;
  Stream<String>? _reasoningStream;

  // Gemini API key - replace with your actual key
  static const String _geminiApiKey = 'AIzaSyCYzjuFXko9kKniCB0wWfvLqxJAGcuuI4w';

  // Fallback Gemini model names (used only if API fetch fails)
  static const List<String> fallbackGeminiModels = [
    'gemini-pro',
    'gemini-pro-vision',
    'gemini-1.5-pro',
    'gemini-1.5-flash',
    'gemini-2.0-flash', // Added new model
  ];

  // Mapping for display names to actual model names
  static const Map<String, String> modelDisplayNameMap = {
    'alvandefault': 'gemini-2.0-flash',
  };

  // Getter for Gemini models (dynamic or fallback)
  List<String> get geminiModels => _availableGeminiModels.isNotEmpty
      ? _availableGeminiModels
      : fallbackGeminiModels;

  // Getter for reasoning stream
  Stream<String>? get reasoningStream => _reasoningStream;

  AIService({
    required this.baseUrl,
    required this.apiKey,
  }) {
    // Initialize HTTP client for OpenAI (if needed)
    _initHttpClient();

    // Initialize Gemini
    _initGemini();
  }

  void _initHttpClient() {
    // Remove trailing slashes from baseUrl if not empty
    final cleanBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

    // Append /v1 if not present and baseUrl is not empty
    final fullBaseUrl = cleanBaseUrl.isEmpty
        ? ''
        : cleanBaseUrl.endsWith('/v1')
            ? cleanBaseUrl
            : '$cleanBaseUrl/v1';

    _dio = Dio(BaseOptions(
      baseUrl: fullBaseUrl,
      headers: {
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => true,
      receiveTimeout: const Duration(seconds: 30),
      connectTimeout: const Duration(seconds: 30),
    ));
  }

  void _initGemini() {
    // This method is now primarily for initial setup if any,
    // _geminiModel and _chatSession are initialized on-demand per call.
    print('[AIService VERBOSE] Initializing Gemini Service. API Key: $_geminiApiKey');
    // Fetch available Gemini models once
    _fetchGeminiModels();
  }

  // Updated to take actual model name for initialization
  void _initializeAndStartChatSession(String actualModelName) {
    try {
      print('[AIService VERBOSE] Initializing Gemini Model: $actualModelName with API Key: $_geminiApiKey');
      _geminiModel = GenerativeModel(
        model: actualModelName, // Use the specific model
        apiKey: _geminiApiKey,
      );
      _chatSession = _geminiModel!.startChat();
      print('[AIService VERBOSE] Gemini Model ($actualModelName) and Chat Session started successfully.');
    } catch (e) {
      print('[AIService ERROR] Error initializing Gemini Model ($actualModelName) or starting chat session: $e');
      _geminiModel = null;
      _chatSession = null;
      throw Exception('Failed to initialize Gemini model $actualModelName: $e');
    }
  }

  Future<void> _fetchGeminiModels() async {
    // In a real app, this might fetch from an API. For now, use fallback.
    _availableGeminiModels = fallbackGeminiModels.toList();
    print('[AIService VERBOSE] Available Gemini models set to: $_availableGeminiModels');
  }

  String _getActualModelName(String modelName) {
    return modelDisplayNameMap[modelName.toLowerCase()] ?? modelName;
  }

  bool isGeminiModel(String modelName) {
    final actualModelName = _getActualModelName(modelName);
    // Clean the model name (remove path prefix if any)
    final cleanName = actualModelName.contains('/') ? actualModelName.split('/').last : actualModelName;
    // Check against the comprehensive fallback list which now includes gemini-2.0-flash
    return fallbackGeminiModels.contains(cleanName.toLowerCase());
  }

  void setModelType(String modelName) {
    // Determine if the model (potentially after mapping "alvandefault") is a Gemini model
    final actualModelName = _getActualModelName(modelName);
    _activeModelType = isGeminiModel(actualModelName) ? AIModelType.gemini : AIModelType.openAI;
    print('[AIService VERBOSE] Active model display name: $modelName, Actual model name: $actualModelName, Type set to: $_activeModelType');
    // _geminiModel and _chatSession will be initialized on demand in streaming methods
  }

  Future<(bool success, String message)> testConnection() async {
    // Get the actual model name if a display name is used
    // This part might need access to the currently selected model from settings if testConnection is generic
    // For now, assuming _activeModelType is correctly set by setModelType
    if (_activeModelType == AIModelType.gemini) {
      // Basic check: ensure API key is present
      if (_geminiApiKey.isEmpty) {
        return (false, 'Gemini API Key is missing.');
      }
      // Could try a lightweight call here if Gemini SDK supports it, e.g., list models
      print('[AIService VERBOSE] Gemini model selected. API key present. Connection considered okay for Gemini.');
      return (true, 'Using Gemini model. API key is present.');
    }

    // OpenAI connection test
    try {
      if (baseUrl.isEmpty || apiKey.isEmpty) {
        return (false, 'Base URL and API key are required');
      }

      print('Testing connection to: ${_dio.options.baseUrl}');

      // First test if the models endpoint is reachable
      final modelsResponse = await _dio.get(
        '/models',
        options: Options(responseType: ResponseType.json),
      );

      print('Models response status: ${modelsResponse.statusCode}');
      print('Models response data: ${modelsResponse.data}');

      if (modelsResponse.statusCode == 401) {
        return (false, 'Invalid API key');
      } else if (modelsResponse.statusCode == 404) {
        return (false, 'Invalid endpoint URL');
      } else if (modelsResponse.statusCode != 200) {
        final errorMessage = modelsResponse.data is Map
            ? modelsResponse.data['error']?.toString()
            : modelsResponse.statusMessage;
        return (false, 'Error: ${modelsResponse.statusCode} - $errorMessage');
      }

      // Get the first available model
      try {
        final data = modelsResponse.data;
        if (data == null || data['data'] == null || !(data['data'] is List)) {
          print('Invalid models data format: $data');
          return (false, 'Invalid models response format');
        }

        final models = (data['data'] as List)
            .where((model) => model['id'] != null)
            .map((model) => model['id'] as String)
            .toList();

        print('Available models: $models');

        if (models.isEmpty) {
          return (false, 'No models available');
        }

        return (true, 'Connection successful');
      } catch (e) {
        print('Error parsing models response: $e');
        return (false, 'Error parsing models response: $e');
      }
    } on DioException catch (e) {
      print('DioException: ${e.type} - ${e.message}');
      print('DioException response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout) {
        return (false, 'Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        return (false, 'Cannot reach server');
      }

      final errorMessage = e.response?.data is Map
          ? e.response?.data['error']?.toString()
          : e.message;
      return (false, 'Connection error: $errorMessage');
    } catch (e) {
      print('Unexpected error: $e');
      return (false, 'Unexpected error: $e');
    }
  }

  Future<List<String>> fetchAvailableModels() async {
    print('[AIService VERBOSE fetchAvailableModels] Fetching available models.');
    Set<String> uniqueDisplayModels = {};

    // Ensure internal Gemini model list is populated
    if (_availableGeminiModels.isEmpty) {
      await _fetchGeminiModels(); // Populates _availableGeminiModels from fallbackGeminiModels
    }

    // Add actual Gemini model names
    uniqueDisplayModels.addAll(_availableGeminiModels);

    // Add display names like "alvandefault"
    modelDisplayNameMap.forEach((displayName, actualName) {
      if (fallbackGeminiModels.contains(actualName)) { // Ensure the mapped model is a known Gemini model
        uniqueDisplayModels.add(displayName);
      }
    });
    
    print('[AIService VERBOSE fetchAvailableModels] Gemini models (including display names) to offer: $uniqueDisplayModels');

    // Try to fetch OpenAI models if connection info is provided
    if (_activeModelType == AIModelType.openAI &&
        baseUrl.isNotEmpty &&
        apiKey.isNotEmpty) {
      try {
        print('Fetching OpenAI models from: ${_dio.options.baseUrl}');
        final response = await _dio.get(
          '/models',
          options: Options(responseType: ResponseType.json),
        );

        print('Models response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          try {
            final data = response.data;
            if (data != null &&
                data['data'] != null &&
                (data['data'] is List)) {
              final openaiModels = (data['data'] as List)
                  .where((model) => model['id'] != null)
                  .map((model) => model['id'] as String)
                  .toList();

              print('Successfully parsed OpenAI models: $openaiModels');
              uniqueDisplayModels.addAll(openaiModels); // Corrected to uniqueDisplayModels
            }
          } catch (e) {
            print('Error parsing OpenAI models: $e');
          }
        }
      } catch (e) {
        print('Error fetching OpenAI models: $e');
      }
    }

    // Convert to list and sort
    List<String> allModels = uniqueDisplayModels.toList(); // Corrected to uniqueDisplayModels
    allModels.sort();
    return allModels;
  }

  Future<Stream<String>> streamChat(String message, String model) async {
    setModelType(model);

    if (_activeModelType == AIModelType.gemini) {
      return _streamGeminiChat(message, model);
    } else {
      return _streamOpenAIChat(message, model);
    }
  }

  Future<Stream<String>> _streamGeminiChat(String message, String model) async {
    // Determine the actual model name to use (e.g., mapping 'alvandefault')
    final actualModelName = _getActualModelName(model);
    print('[AIService VERBOSE _streamGeminiChat] Display model: $model, Actual model: $actualModelName');

    // Initialize model and session if needed, or if the model has changed.
    if (_geminiModel == null || _chatSession == null || _lastInitializedActualModelName != actualModelName) {
      print('[AIService VERBOSE _streamGeminiChat] Model changed or not initialized. Current actual: $actualModelName, Last init: $_lastInitializedActualModelName. Initializing session.');
      _initializeAndStartChatSession(actualModelName);
      _lastInitializedActualModelName = actualModelName;
    }

    if (_geminiModel == null || _chatSession == null) {
      print('[AIService ERROR _streamGeminiChat] Gemini model or chat session is null after attempting initialization for $actualModelName.');
      // Add to reasoning stream before throwing
      _reasoningStreamController = StreamController<String>(); // Ensure controller exists
      _reasoningStream = _reasoningStreamController!.stream;
      addReasoningText("ERROR: Gemini model $actualModelName could not be initialized. Check API key and model name.\n");
      _reasoningStreamController!.close();
      throw Exception('Gemini is not initialized for model $actualModelName. API Key: $_geminiApiKey');
    }
    
    final StreamController<String> controller = StreamController<String>();
    _reasoningStreamController = StreamController<String>();
    _reasoningStream = _reasoningStreamController!.stream;

    print('[AIService VERBOSE _streamGeminiChat] Using API Key: $_geminiApiKey for model $actualModelName');
    addReasoningText("Attempting to send message to $actualModelName...\n");

    _chatSession!.sendMessage(Content.text(message)).then((response) {
      print('[AIService VERBOSE _streamGeminiChat] Received response object from Gemini for model $actualModelName.');
      // It's good practice to log the whole response structure if possible, or key parts.
      // For example, if there are error fields in the response.
      // print('[AIService VERBOSE _streamGeminiChat] Gemini Raw Response: ${response}'); // Might be too verbose or complex object

      final candidate = response.candidates.firstOrNull;
      if (candidate == null) {
        print('[AIService ERROR _streamGeminiChat] No candidates in Gemini response for model $actualModelName.');
        addReasoningText("ERROR: No response candidates received from $actualModelName.\n");
        controller.addError('No response candidates from Gemini.');
        controller.close();
        _reasoningStreamController?.close();
        return;
      }
      
      // Log safety ratings if available and relevant for debugging
      // candidate.safetyRatings.forEach((rating) {
      //   print('[AIService VERBOSE _streamGeminiChat] Safety Rating - Category: ${rating.category}, Probability: ${rating.probability}');
      // });

      // Check for finish reason
      if (candidate.finishReason != null && candidate.finishReason != FinishReason.stop) {
        print('[AIService WARNING _streamGeminiChat] Gemini response finished with reason: ${candidate.finishReason}. Message: ${candidate.finishMessage}');
        addReasoningText("Warning: Response from $actualModelName finished due to ${candidate.finishReason}. ${candidate.finishMessage}\n");
      }

      String fullText = candidate.content.parts
          .whereType<TextPart>()
          .map((part) => part.text)
          .join('');
      
      print('[AIService VERBOSE _streamGeminiChat] Extracted text from Gemini response for $actualModelName: "$fullText" (Length: ${fullText.length})');
      addReasoningText("Received response from $actualModelName. Length: ${fullText.length} chars.\n");

      if (fullText.isEmpty) {
        if (candidate.finishReason != null && candidate.finishReason != FinishReason.stop) {
             fullText = "Response processing was interrupted due to: ${candidate.finishReason}.";
        } else {
            fullText = "I'm not sure how to respond to that (received empty text).";
        }
        print('[AIService WARNING _streamGeminiChat] Gemini response text is empty for model $actualModelName.');
        addReasoningText("Warning: Received empty text response from $actualModelName.\n");
      }

      // Simulate streaming
      int charIndex = 0;
      Timer.periodic(const Duration(milliseconds: 15), (timer) {
        if (charIndex < fullText.length) {
          controller.add(fullText[charIndex]);
          charIndex++;
        } else {
          timer.cancel();
          controller.close();
          addReasoningText("Streaming complete for $actualModelName.\n");
          _reasoningStreamController?.close();
          _reasoningStreamController = null; // Clean up
        }
      });
    }).catchError((e, stackTrace) {
      print('[AIService ERROR _streamGeminiChat] Error sending message or processing response for $actualModelName: $e');
      print('[AIService ERROR _streamGeminiChat] StackTrace: $stackTrace');
      addReasoningText("ERROR sending/processing message for $actualModelName: $e\n");
      controller.addError('Error with Gemini model $actualModelName: $e');
      controller.close();

      // Close the reasoning stream controller
      _reasoningStreamController?.close();
      _reasoningStreamController = null;
    }); // Added semicolon

    return controller.stream;
  }

  // New method to stream chat with conversation history
  Future<Stream<String>> streamChatWithHistory(String message, String model,
      List<Map<String, String>> conversationHistory) async {
    setModelType(model);

    if (_activeModelType == AIModelType.gemini) {
      return _streamGeminiChatWithHistory(message, model, conversationHistory);
    } else {
      return _streamOpenAIChatWithHistory(message, model, conversationHistory);
    }
  }

  Future<Stream<String>> _streamGeminiChatWithHistory(String message,
      String model, List<Map<String, String>> conversationHistory) async {
    final actualModelName = _getActualModelName(model);
    print('[AIService VERBOSE _streamGeminiChatWithHistory] Display model: $model, Actual model: $actualModelName');

    // Initialize model and session if needed, or if the model has changed.
    if (_geminiModel == null || _chatSession == null || _lastInitializedActualModelName != actualModelName) {
      print('[AIService VERBOSE _streamGeminiChatWithHistory] Model changed or not initialized. Current actual: $actualModelName, Last init: $_lastInitializedActualModelName. Initializing session.');
      _initializeAndStartChatSession(actualModelName);
      _lastInitializedActualModelName = actualModelName;
    }
    
    if (_geminiModel == null || _chatSession == null) {
      print('[AIService ERROR _streamGeminiChatWithHistory] Gemini model or chat session is null after attempting init for $actualModelName.');
      _reasoningStreamController = StreamController<String>(); // Ensure controller exists
      _reasoningStream = _reasoningStreamController!.stream;
      addReasoningText("ERROR: Gemini model $actualModelName could not be initialized. Check API key and model name.\n");
      _reasoningStreamController!.close();
      throw Exception('Gemini is not initialized for model $actualModelName. API Key: $_geminiApiKey');
    }

    final StreamController<String> controller = StreamController<String>();
    _reasoningStreamController = StreamController<String>();
    _reasoningStream = _reasoningStreamController!.stream;

    print('[AIService VERBOSE _streamGeminiChatWithHistory] Using API Key: $_geminiApiKey for model $actualModelName');
    print('[AIService VERBOSE _streamGeminiChatWithHistory] Sending message: "$message" with history (count: ${conversationHistory.length})');
    // Log history content if needed for deep debugging, be mindful of verbosity
    // conversationHistory.forEach((item) => print('[AIService VERBOSE] History item: Role: ${item["role"]}, Parts: ${item["parts"]}'));

    addReasoningText("Attempting to send message to $actualModelName with history...\n");

    // Convert history for Gemini SDK
    final geminiHistory = conversationHistory.map((msg) {
      return Content(msg["role"] ?? "user", [TextPart(msg["parts"] ?? "")]);
    }).toList();

    // The google_generative_ai package's startChat(history: ...) is for setting initial context.
    // For ongoing chat, you typically send new messages to the existing _chatSession.
    // If the history is meant to be the *entire* context for a fresh session each time:
    // _chatSession = _geminiModel!.startChat(history: geminiHistory);
    // Then send the new message:
    // final response = await _chatSession!.sendMessage(Content.text(message));

    // However, if _chatSession is supposed to be continuous and accumulate history:
    // You'd send the new message, and the SDK's _chatSession would internally manage history.
    // The current _geminiModel.startChat(history: history) in the original code suggests a new session with history.
    // Let's stick to re-creating chat session with history for now as per original structure,
    // but this might be inefficient if the SDK supports continuous chat sessions better.
    
    // Re-initialize chat session with the provided history for this specific call
    // This ensures the current call uses exactly the history provided.
    ChatSession currentCallChatSession;
    try {
        print('[AIService VERBOSE _streamGeminiChatWithHistory] Starting new chat session for $actualModelName with provided history (count: ${geminiHistory.length}).');
        currentCallChatSession = _geminiModel!.startChat(history: geminiHistory);
    } catch (e) {
        print('[AIService ERROR _streamGeminiChatWithHistory] Failed to start chat session with history for $actualModelName: $e');
        addReasoningText("ERROR: Failed to start chat session with history for $actualModelName: $e\n");
        controller.addError('Failed to start chat session with history for $actualModelName: $e');
        controller.close();
        _reasoningStreamController?.close();
        _reasoningStreamController = null;
        return controller.stream;
    }


    currentCallChatSession.sendMessage(Content.text(message)).then((response) {
      print('[AIService VERBOSE _streamGeminiChatWithHistory] Received response object from Gemini for model $actualModelName.');
      // print('[AIService VERBOSE _streamGeminiChatWithHistory] Gemini Raw Response: ${response}');

      final candidate = response.candidates.firstOrNull;
      if (candidate == null) {
        print('[AIService ERROR _streamGeminiChatWithHistory] No candidates in Gemini response for model $actualModelName.');
        addReasoningText("ERROR: No response candidates received from $actualModelName.\n");
        controller.addError('No response candidates from Gemini.');
        controller.close();
        _reasoningStreamController?.close();
        return;
      }

      // candidate.safetyRatings.forEach((rating) {
      //   print('[AIService VERBOSE _streamGeminiChatWithHistory] Safety Rating - Category: ${rating.category}, Probability: ${rating.probability}');
      // });
      
      if (candidate.finishReason != null && candidate.finishReason != FinishReason.stop) {
        print('[AIService WARNING _streamGeminiChatWithHistory] Gemini response finished with reason: ${candidate.finishReason}. Message: ${candidate.finishMessage}');
        addReasoningText("Warning: Response from $actualModelName finished due to ${candidate.finishReason}. ${candidate.finishMessage}\n");
      }

      String fullText = candidate.content.parts
          .whereType<TextPart>()
          .map((part) => part.text)
          .join('');

      print('[AIService VERBOSE _streamGeminiChatWithHistory] Extracted text from Gemini response for $actualModelName: "$fullText" (Length: ${fullText.length})');
      addReasoningText("Received response from $actualModelName. Length: ${fullText.length} chars.\n");
      
      if (fullText.isEmpty) {
        if (candidate.finishReason != null && candidate.finishReason != FinishReason.stop) {
             fullText = "Response processing was interrupted due to: ${candidate.finishReason}.";
        } else {
            fullText = "I'm not sure how to respond to that (received empty text).";
        }
        print('[AIService WARNING _streamGeminiChatWithHistory] Gemini response text is empty for model $actualModelName.');
        addReasoningText("Warning: Received empty text response from $actualModelName.\n");
      }

      int charIndex = 0;
      Timer.periodic(const Duration(milliseconds: 15), (timer) {
        if (charIndex < fullText.length) {
          controller.add(fullText[charIndex]);
          charIndex++;
        } else {
          timer.cancel();
          controller.close();
          addReasoningText("Streaming complete for $actualModelName.\n");
          _reasoningStreamController?.close();
          _reasoningStreamController = null; // Clean up
        }
      });
    }).catchError((e, stackTrace) {
      print('[AIService ERROR _streamGeminiChatWithHistory] Error sending message or processing response for $actualModelName: $e');
      print('[AIService ERROR _streamGeminiChatWithHistory] StackTrace: $stackTrace');
      addReasoningText("ERROR sending/processing message for $actualModelName: $e\n");
      controller.addError('Error with Gemini model $actualModelName: $e');
      controller.close();

      // Close the reasoning stream controller
      _reasoningStreamController?.close();
      _reasoningStreamController = null;
    }); // Added semicolon

    return controller.stream;
  }

  Future<Stream<String>> _streamOpenAIChat(String message, String model) async {
    if (baseUrl.isEmpty || apiKey.isEmpty) {
      throw Exception('Base URL and API key are required');
    }

    try {
      print('Streaming chat with OpenAI model: $model');
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': message}
          ],
          'stream': true,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get response: ${response.statusCode}');
      }

      final Stream<Uint8List> responseStream = response.data.stream;
      final Stream<String> lines = responseStream
          .transform(StreamTransformer<Uint8List, String>.fromHandlers(
        handleData: (data, sink) {
          sink.add(utf8.decode(data));
        },
      )).transform(const LineSplitter());

      // Transform SSE format to actual content
      final Stream<String> contentStream = lines.transform(
        StreamTransformer<String, String>.fromHandlers(
          handleData: (String line, EventSink<String> sink) {
            if (line.startsWith('data: ')) {
              String data = line.substring(6);
              if (data.trim() == '[DONE]') return;

              try {
                Map<String, dynamic> json = jsonDecode(data);
                String? content = json['choices']?[0]?['delta']?['content'];
                if (content != null) {
                  sink.add(content);
                }
              } catch (e) {
                print('Error parsing JSON: $e');
                print('Problematic line: $line');
              }
            }
          },
          handleError: (error, stackTrace, sink) {
            print('Stream error: $error');
            print('Stack trace: $stackTrace');
            sink.addError('Error processing response: $error');
          },
          handleDone: (sink) {
            sink.close();
          },
        ),
      );

      return contentStream;
    } catch (e, stackTrace) {
      print('Error in streamChat: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to stream chat: $e');
    }
  }

  Future<Stream<String>> _streamOpenAIChatWithHistory(String message,
      String model, List<Map<String, String>> conversationHistory) async {
    if (baseUrl.isEmpty || apiKey.isEmpty) {
      throw Exception('Base URL and API key are required');
    }

    try {
      print('Streaming chat with OpenAI model: $model');

      // Convert conversation history to OpenAI format
      final messages = conversationHistory
          .map((msg) => {'role': msg['role'], 'content': msg['parts']})
          .toList();

      // Add the current message
      messages.add({'role': 'user', 'content': message});

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'stream': true,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get response: ${response.statusCode}');
      }

      final Stream<Uint8List> responseStream = response.data.stream;
      final Stream<String> lines = responseStream
          .transform(StreamTransformer<Uint8List, String>.fromHandlers(
        handleData: (data, sink) {
          sink.add(utf8.decode(data));
        },
      )).transform(const LineSplitter());

      // Transform SSE format to actual content
      final Stream<String> contentStream = lines.transform(
        StreamTransformer<String, String>.fromHandlers(
          handleData: (String line, EventSink<String> sink) {
            if (line.startsWith('data: ')) {
              String data = line.substring(6);
              if (data.trim() == '[DONE]') return;

              try {
                Map<String, dynamic> json = jsonDecode(data);
                String? content = json['choices']?[0]?['delta']?['content'];
                if (content != null) {
                  sink.add(content);
                }
              } catch (e) {
                print('Error parsing JSON: $e');
                print('Problematic line: $line');
              }
            }
          },
          handleError: (error, stackTrace, sink) {
            print('Stream error: $error');
            print('Stack trace: $stackTrace');
            sink.addError('Error processing response: $error');
          },
          handleDone: (sink) {
            sink.close();
          },
        ),
      );

      return contentStream;
    } catch (e, stackTrace) {
      print('Error in streamChat: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to stream chat: $e');
    }
  }

  // Public method to refresh Gemini models
  Future<void> refreshGeminiModels() async {
    await _fetchGeminiModels();
  }

  // Method to add reasoning text to the stream
  void addReasoningText(String text) {
    if (_reasoningStreamController != null &&
        !_reasoningStreamController!.isClosed) {
      _reasoningStreamController!.add(text);
    }
  }

  // Method to close the reasoning stream
  void closeReasoningStream() {
    if (_reasoningStreamController != null &&
        !_reasoningStreamController!.isClosed) {
      _reasoningStreamController!.close();
      _reasoningStreamController = null;
    }
  }
}
