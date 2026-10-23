
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String defaultAiModel = 'qwen/qwen3.8-27b';

abstract class AiProvider {
  Future<Map<String, dynamic>?> generateJson({
    required String systemPrompt,
    required String userPrompt,
  });

  Future<Map<String, dynamic>?> generateVisionJson({
    required String prompt,
    required List<int> bytes,
    String? mimeType,
  });
}

/// OpenAI-compatible client for the Vercel-hosted Groq proxy.
///
/// Web uses `/api/groq`; the serverless function securely attaches the API key
/// and selects the model configured in `api/groq.ts`.
///
/// For a native build, set AI_BASE_URL to your deployed proxy URL, for example:
/// https://your-domain.vercel.app/api/groq
class OpenAiCompatibleProvider implements AiProvider {
  final String baseUrl;

  /// Kept for constructor compatibility with existing callers.
  /// The key is not sent to the proxy or embedded into web requests.
  final String apiKey;

  /// Kept for constructor compatibility. The server selects the actual model.
  final String model;

  String? lastError;

  OpenAiCompatibleProvider({
    String? baseUrl,
    String? apiKey,
    String? model,
  })  : baseUrl = baseUrl ??
            const String.fromEnvironment('AI_BASE_URL', defaultValue: ''),
        apiKey = apiKey ?? const String.fromEnvironment('AI_API_KEY'),
        model = model ??
            const String.fromEnvironment(
              'AI_MODEL',
              defaultValue: defaultAiModel,
            );

  String get _effectiveBaseUrl {
    if (baseUrl.trim().isNotEmpty) {
      return baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    }
    if (kIsWeb) return '/api/groq';
    return '';
  }

  bool get _isProxyEndpoint {
    final value = _effectiveBaseUrl;
    return value == '/api/groq' || value.endsWith('/api/groq');
  }

  bool get configured => _isProxyEndpoint;

  Uri get _completionUri => Uri.parse(_effectiveBaseUrl);

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
      };

  Map<String, dynamic>? _decodeJsonObject(http.Response response) {
    lastError = null;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = 'AI request failed with HTTP ${response.statusCode}.';

      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] is String) {
          detail = (body['error'] as String).trim();
        }
        if (body is Map && body['code'] is String) {
          detail = '$detail [${body['code']}]';
        }
      } catch (_) {
        // Retain the HTTP status fallback for non-JSON responses.
      }

      lastError = detail;
      if (kDebugMode) {
        debugPrint('AI request failed (${response.statusCode}): $detail');
      }
      return null;
    }

    try {
      final outer = jsonDecode(response.body);

      if (outer is! Map) {
        lastError = 'AI service returned an unexpected response.';
        return null;
      }

      final choices = outer['choices'];
      if (choices is! List || choices.isEmpty || choices.first is! Map) {
        lastError = 'AI service returned no answer.';
        return null;
      }

      final message = (choices.first as Map)['message'];
      if (message is! Map) {
        lastError = 'AI service returned an unreadable answer.';
        return null;
      }

      final content = message['content'];
      if (content is! String || content.trim().isEmpty) {
        lastError = 'AI service returned an empty answer.';
        return null;
      }

      final decoded = jsonDecode(content);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      lastError = 'AI service answer was not valid JSON.';
      return null;
    } catch (error) {
      lastError = 'AI service response could not be decoded.';
      if (kDebugMode) {
        debugPrint('Could not decode AI JSON response: $error');
      }
      return null;
    }
  }

  Future<http.Response> _post(Map<String, dynamic> payload) {
    return http
        .post(
          _completionUri,
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 55));
  }

  @override
  Future<Map<String, dynamic>?> generateJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    lastError = null;

    if (!configured) {
      lastError =
          'AI is not configured. Set AI_BASE_URL to the deployed /api/groq endpoint.';
      if (kDebugMode) debugPrint(lastError);
      return null;
    }

    try {
      final response = await _post({
        'model': model,
        'temperature': 0.2,
        'max_completion_tokens': 1024,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      });

      return _decodeJsonObject(response);
    } catch (error) {
      lastError = error.toString().contains('TimeoutException')
          ? 'The AI service took too long to respond.'
          : 'Could not connect to the AI service.';

      if (kDebugMode) debugPrint('AI text request failed: $error');
      return null;
    }
  }

  String _detectMimeType(List<int> bytes, String? provided) {
    if (provided != null && provided.trim().isNotEmpty) {
      return provided.trim();
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }

    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }

    if (bytes.length >= 6) {
      final signature = String.fromCharCodes(bytes.sublist(0, 6));
      if (signature == 'GIF87a' || signature == 'GIF89a') {
        return 'image/gif';
      }
    }

    return 'image/jpeg';
  }

  @override
  Future<Map<String, dynamic>?> generateVisionJson({
    required String prompt,
    required List<int> bytes,
    String? mimeType,
  }) async {
    lastError = null;

    if (!configured || bytes.isEmpty) {
      lastError = !configured
          ? 'AI is not configured for this build.'
          : 'The selected image is empty.';

      if (kDebugMode && bytes.isEmpty) {
        debugPrint('Vision request skipped: image bytes are empty.');
      }
      return null;
    }

    try {
      final data = base64Encode(bytes);
      final media = _detectMimeType(bytes, mimeType);

      final response = await _post({
        'model': model,
        'temperature': 0.0,
        'max_completion_tokens': 512,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$media;base64,$data',
                },
              },
            ],
          },
        ],
      });

      return _decodeJsonObject(response);
    } catch (error) {
      lastError = error.toString().contains('TimeoutException')
          ? 'The AI service took too long to respond.'
          : 'Could not connect to the AI service.';

      if (kDebugMode) debugPrint('AI image request failed: $error');
      return null;
    }
  }
}
