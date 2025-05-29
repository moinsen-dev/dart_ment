/// Utility class for parsing and cleaning AI responses
class AIResponseParser {
  /// Parse and extract code from AI response
  static String? extractCode(String response) {
    if (response.isEmpty) return null;

    final cleaned = response.trim();

    // Strategy 1: Extract from markdown code blocks
    final codeBlockPatterns = [
      // Match ```dart ... ```
      RegExp(r'```dart\s*\n(.*?)\n```', multiLine: true, dotAll: true),
      // Match ``` ... ```
      RegExp(r'```\s*\n(.*?)\n```', multiLine: true, dotAll: true),
      // Match ```language ... ```
      RegExp(r'```\w+\s*\n(.*?)\n```', multiLine: true, dotAll: true),
    ];

    for (final pattern in codeBlockPatterns) {
      final match = pattern.firstMatch(cleaned);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    // Strategy 2: Remove common prefixes/suffixes
    final lines = cleaned.split('\n');
    final filteredLines = <String>[];
    var inCodeBlock = false;

    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Skip markdown code fence lines
      if (trimmedLine == '```dart' || 
          trimmedLine == '```' || 
          trimmedLine.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      // Skip common AI explanation lines
      if (!inCodeBlock && _isExplanationLine(trimmedLine)) {
        continue;
      }

      filteredLines.add(line);
    }

    final result = filteredLines.join('\n').trim();
    
    // Strategy 3: Validate the result looks like Dart code
    if (_looksLikeDartCode(result)) {
      return result;
    }

    // If all strategies fail, return the original cleaned response
    return cleaned;
  }

  /// Check if a line looks like an explanation rather than code
  static bool _isExplanationLine(String line) {
    final explanationPatterns = [
      'here is', "here's", 'this is', 'the following',
      'fixed code', 'corrected code', 'updated code',
      'solution:', 'fix:', 'output:',
    ];

    final lowerLine = line.toLowerCase();
    return explanationPatterns.any(lowerLine.startsWith);
  }

  /// Basic heuristic to check if text looks like Dart code
  static bool _looksLikeDartCode(String text) {
    if (text.isEmpty) return false;

    // Check for common Dart keywords/patterns
    final dartPatterns = [
      RegExp(r'\bclass\s+\w+'),
      RegExp(r'\bvoid\s+\w+'),
      RegExp(r'\bfinal\s+\w+'),
      RegExp(r'\bconst\s+\w+'),
      RegExp(r'\bvar\s+\w+'),
      // Match import statements
      RegExp(r'\bimport\s+'),
      RegExp(r'\breturn\s+'),
      RegExp(r'^\s*}'),
      RegExp(r'^\s*{'),
    ];

    return dartPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Extract multiple code blocks from a response
  static List<String> extractAllCodeBlocks(String response) {
    if (response.isEmpty) return [];

    final blocks = <String>[];
    final pattern = RegExp(
      r'```(?:dart)?\s*\n(.*?)\n```',
      multiLine: true,
      dotAll: true,
    );

    for (final match in pattern.allMatches(response)) {
      final code = match.group(1)?.trim();
      if (code != null && code.isNotEmpty) {
        blocks.add(code);
      }
    }

    return blocks;
  }
}
