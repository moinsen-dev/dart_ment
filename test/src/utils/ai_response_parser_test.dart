import 'package:dart_ment/src/utils/ai_response_parser.dart';
import 'package:test/test.dart';

void main() {
  group('AIResponseParser', () {
    group('extractCode', () {
      test('extracts code from markdown code block with dart language', () {
        const response = '''
Here's the fixed code:

```dart
class Example {
  final String name = 'test';
}
```

The code has been corrected.
''';

        final result = AIResponseParser.extractCode(response);
        expect(result, equals("class Example {\n  final String name = 'test';\n}"));
      });

      test('extracts code from plain markdown code block', () {
        const response = '''
```
class Example {
  final String name = 'test';
}
```
''';

        final result = AIResponseParser.extractCode(response);
        expect(result, equals("class Example {\n  final String name = 'test';\n}"));
      });

      test('returns clean code when no markdown formatting', () {
        const response = '''class Example {
  final String name = 'test';
}''';

        final result = AIResponseParser.extractCode(response);
        expect(result, equals("class Example {\n  final String name = 'test';\n}"));
      });

      test('removes explanation lines before code', () {
        const response = '''Here is the fixed code:
class Example {
  final String name = 'test';
}''';

        final result = AIResponseParser.extractCode(response);
        expect(result, equals("class Example {\n  final String name = 'test';\n}"));
      });

      test('handles response with multiple code blocks', () {
        const response = '''
First block:
```dart
class A {}
```

Second block:
```dart
class B {}
```
''';

        // Should extract the first code block
        final result = AIResponseParser.extractCode(response);
        expect(result, equals('class A {}'));
      });

      test('handles malformed markdown', () {
        const response = '''```dart
import 'dart:io';

class Test {
  void method() {
    print('Hello');
  }
}
```''';

        final result = AIResponseParser.extractCode(response);
        expect(result, contains("import 'dart:io';"));
        expect(result, contains('class Test'));
      });

      test('returns null for empty response', () {
        final result = AIResponseParser.extractCode('');
        expect(result, isNull);
      });
    });

    group('extractAllCodeBlocks', () {
      test('extracts multiple code blocks', () {
        const response = '''
```dart
class A {}
```

Some text

```dart
class B {}
```
''';

        final blocks = AIResponseParser.extractAllCodeBlocks(response);
        expect(blocks, hasLength(2));
        expect(blocks[0], equals('class A {}'));
        expect(blocks[1], equals('class B {}'));
      });

      test('returns empty list for no code blocks', () {
        const response = 'Just plain text without code blocks';
        final blocks = AIResponseParser.extractAllCodeBlocks(response);
        expect(blocks, isEmpty);
      });
    });
  });
}