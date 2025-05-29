import 'package:args/command_runner.dart';
import 'package:dart_ment/src/commands/fix_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('fix', () {
    late CommandRunner<int> commandRunner;
    late Logger logger;

    setUp(() {
      logger = _MockLogger();
      commandRunner = CommandRunner<int>('test', 'Test CLI')
        ..addCommand(FixCommand(logger: logger));
    });

    test('can be instantiated', () {
      expect(FixCommand(logger: logger), isNotNull);
    });

    test('has correct name', () {
      final command = FixCommand(logger: logger);
      expect(command.name, equals('fix'));
    });

    test('has correct description', () {
      final command = FixCommand(logger: logger);
      expect(
        command.description,
        equals('Fix linting issues using AI assistance.'),
      );
    });

    test('accepts config option', () async {
      final command = FixCommand(logger: logger);
      final argParser = command.argParser;
      
      expect(argParser.options.containsKey('config'), isTrue);
      expect(argParser.options['config']!.abbr, equals('c'));
    });

    test('accepts api-key option', () async {
      final command = FixCommand(logger: logger);
      final argParser = command.argParser;
      
      expect(argParser.options.containsKey('api-key'), isTrue);
    });

    test('accepts dry-run flag', () async {
      final command = FixCommand(logger: logger);
      final argParser = command.argParser;
      
      expect(argParser.options.containsKey('dry-run'), isTrue);
      expect(argParser.options['dry-run']!.negatable, isFalse);
    });

    test('requires API key', () async {
      when(() => logger.info(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);
      
      final result = await commandRunner.run(['fix']);
      
      expect(result, equals(ExitCode.config.code));
      verify(
        () => logger.err(
          'API key not found. Please provide it via --api-key flag, '
          'config file, or GEMINI_API_KEY environment variable.',
        ),
      ).called(1);
    });
  });
}
