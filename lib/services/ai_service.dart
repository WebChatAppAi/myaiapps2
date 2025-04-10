import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'dart:convert';

class AIService {
  late final Dio _dio;
  String baseUrl;
  String apiKey;

  AIService({
    required this.baseUrl,
    required this.apiKey,
  }) {
    print('Creating AIService with baseUrl: $baseUrl, apiKey: $apiKey');

    // Remove trailing slashes from baseUrl if not empty
    final cleanBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

    // Append /v1 if not present and baseUrl is not empty
    final fullBaseUrl = cleanBaseUrl.isEmpty
        ? ''
        : cleanBaseUrl.endsWith('/v1')
            ? cleanBaseUrl
            : '$cleanBaseUrl/v1';

    print('Initialized Dio with baseUrl: $fullBaseUrl');

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

  Future<(bool success, String message)> testConnection() async {
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
    try {
      if (baseUrl.isEmpty || apiKey.isEmpty) {
        print('Base URL or API key is empty');
        return [];
      }

      print('Fetching models from: ${_dio.options.baseUrl}');
      final response = await _dio.get(
        '/models',
        options: Options(responseType: ResponseType.json),
      );

      print('Models response status: ${response.statusCode}');
      print('Models response data: ${response.data}');

      if (response.statusCode == 401) {
        print('Invalid API key');
        return [];
      } else if (response.statusCode == 404) {
        print('Invalid endpoint URL');
        return [];
      } else if (response.statusCode != 200) {
        final errorMessage = response.data is Map
            ? response.data['error']?.toString() ?? 'Unknown error'
            : response.statusMessage ?? 'Unknown error';
        print('Error: ${response.statusCode} - $errorMessage');
        return [];
      }

      try {
        final data = response.data;
        if (data == null || data['data'] == null || !(data['data'] is List)) {
          print('Invalid models data format: $data');
          return [];
        }

        final List<String> models = (data['data'] as List)
            .where((model) => model['id'] != null)
            .map((model) => model['id'] as String)
            .toSet()
            .toList()
          ..sort();

        print('Successfully parsed models: $models');

        if (models.isEmpty) {
          print('No models found in response');
          return [];
        }

        return models;
      } catch (e) {
        print('Error parsing models: $e');
        return [];
      }
    } on DioException catch (e) {
      print('DioException while fetching models: ${e.type} - ${e.message}');
      print('DioException response: ${e.response?.data}');
      return [];
    } catch (e) {
      print('Unexpected error while fetching models: $e');
      return [];
    }
  }

  Future<Stream<String>> streamChat(String message, String model) async {
    if (baseUrl.isEmpty || apiKey.isEmpty) {
      throw Exception('Base URL and API key are required');
    }

    try {
      print('Streaming chat with model: $model');
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
}
