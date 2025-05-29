import 'package:flutter_gemini/flutter_gemini.dart';

/// Service for interacting with Google Gemini AI
class GeminiService {
  GeminiService({required this.apiKey});

  final String apiKey;

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

Provide only the fixed code without explanations. The code should be properly formatted and follow Dart best practices.
''';

    try {
      final response = await Gemini.instance.prompt(
        parts: [
          Part.text(prompt),
        ],
      );

      return response?.output;
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
