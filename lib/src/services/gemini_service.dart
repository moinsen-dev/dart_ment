import 'dart:convert';
import 'package:dart_ment/src/models/ai_models.dart';
import 'package:dart_ment/src/utils/ai_response_parser.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with Google Gemini AI
class GeminiService {
  GeminiService({required this.apiKey, this.model});

  final String apiKey;
  final AIModel? model;

  /// Initialize the Gemini service
  void initialize() {
    // No initialization needed for HTTP client
  }

  /// Generate a fix suggestion for the given code issue
  Future<String?> generateFix({
    required String code,
    required String issue,
    required String filePath,
  }) async {
    final prompt =
        '''
You are a Dart/Flutter expert. Fix the following linting issue in the code.

File: $filePath
Issue: $issue

Code:
```dart
$code
```

IMPORTANT: Return ONLY the fixed Dart code without any markdown formatting, code fences, or explanations. Do not include ```dart or ``` in your response. The response should be valid Dart code that can be directly written to a file.
''';

    try {
      final response = await _makeGeminiRequest(prompt);
      if (response == null) return null;

      // Use AIResponseParser to extract clean code
      return AIResponseParser.extractCode(response);
    } catch (e) {
      throw Exception('Failed to generate fix: $e');
    }
  }

  /// Analyze code and provide suggestions
  Future<List<String>> analyzeCode({
    required String code,
    required String filePath,
  }) async {
    final prompt =
        '''
You are a Dart/Flutter expert. Analyze the following code and provide improvement suggestions.

File: $filePath

Code:
```dart
$code
```

Provide a list of specific, actionable suggestions to improve code quality, performance, and maintainability. Format each suggestion as a bullet point.
''';

    try {
      final response = await _makeGeminiRequest(prompt);
      if (response == null) return [];

      // Parse the response into a list of suggestions
      final suggestions = response
          .split('\n')
          .where(
            (line) =>
                line.trim().startsWith('•') || line.trim().startsWith('-'),
          )
          .map((line) => line.trim().substring(1).trim())
          .toList();

      return suggestions;
    } catch (e) {
      throw Exception('Failed to analyze code: $e');
    }
  }

  /// Make a request to the Gemini API
  Future<String?> _makeGeminiRequest(String prompt) async {
    final modelId = model?.id ?? 'gemini-1.5-flash';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey',
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': 8192,
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0] as Map<String, dynamic>;
          final content = candidate['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final part = parts[0] as Map<String, dynamic>;
            return part['text'] as String?;
          }
        }
      } else {
        throw Exception(
          'API request failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to make API request: $e');
    }

    return null;
  }
}
