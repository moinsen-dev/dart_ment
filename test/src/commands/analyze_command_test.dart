import 'package:dart_ment/src/commands/analyze_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('analyze', () {
    late Logger logger;

    setUp(() {
      logger = _MockLogger();
    });

    test('can be instantiated', () {
      expect(AnalyzeCommand(logger: logger), isNotNull);
    });

    test('has correct name', () {
      final command = AnalyzeCommand(logger: logger);
      expect(command.name, equals('analyze'));
    });

    test('has correct description', () {
      final command = AnalyzeCommand(logger: logger);
      expect(
        command.description,
        equals(
          'Analyze code quality and suggest improvements.\n'
          'Usage: ment analyze [path]',
        ),
      );
    });

    test('accepts config option', () async {
      final command = AnalyzeCommand(logger: logger);
      final argParser = command.argParser;

      expect(argParser.options.containsKey('config'), isTrue);
      expect(argParser.options['config']!.abbr, equals('c'));
    });

    test('accepts api-key option', () async {
      final command = AnalyzeCommand(logger: logger);
      final argParser = command.argParser;

      expect(argParser.options.containsKey('api-key'), isTrue);
    });

    test('accepts suggestions flag', () async {
      final command = AnalyzeCommand(logger: logger);
      final argParser = command.argParser;

      expect(argParser.options.containsKey('suggestions'), isTrue);
      expect(argParser.options['suggestions']!.abbr, equals('s'));
      expect(argParser.options['suggestions']!.defaultsTo, isTrue);
    });

    test('accepts apply-fixes flag', () async {
      final command = AnalyzeCommand(logger: logger);
      final argParser = command.argParser;

      expect(argParser.options.containsKey('apply-fixes'), isTrue);
      expect(argParser.options['apply-fixes']!.negatable, isFalse);
    });

    test('accepts all-files flag', () async {
      final command = AnalyzeCommand(logger: logger);
      final argParser = command.argParser;

      expect(argParser.options.containsKey('all-files'), isTrue);
      expect(argParser.options['all-files']!.negatable, isFalse);
    });
  });
}
