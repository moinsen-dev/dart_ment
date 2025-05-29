import 'package:dart_ment/src/models/ai_models.dart';
import 'package:dart_ment/src/utils/ai_response_parser.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

/// Service for interacting with Google Gemini AI
class GeminiService {
  GeminiService({required this.apiKey, this.model});

  final String apiKey;
  final AIModel? model;

  /// Initialize the Gemini service
  void initialize() {
    Gemini.init(apiKey: apiKey);
  }

  /// Generate a fix suggestion for the given code issue
  Future<String?> generateFix({
    required String code,
    required String issue,
    required String filePath,
  }) async {
    final prompt = '''
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
      final response = await Gemini.instance.prompt(
        parts: [
          Part.text(prompt),
        ],
        model: model?.id,
      );

      if (response?.output == null) return null;

      // Use AIResponseParser to extract clean code
      return AIResponseParser.extractCode(response!.output!);
    } catch (e) {
      throw Exception('Failed to generate fix: $e');
    }
  }

  /// Analyze code and provide suggestions
  Future<List<String>> analyzeCode({
    required String code,
    required String filePath,
  }) async {
    final prompt = '''
You are a Dart/Flutter expert. Analyze the following code and provide improvement suggestions.

File: $filePath

Code:
```dart
$code
```

Provide a list of specific, actionable suggestions to improve code quality, performance, and maintainability. Format each suggestion as a bullet point.
''';

    try {
      final response = await Gemini.instance.prompt(
        parts: [
          Part.text(prompt),
        ],
        model: model?.id,
      );

      if (response?.output == null) return [];

      // Parse the response into a list of suggestions
      final suggestions = response!.output!
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

}
