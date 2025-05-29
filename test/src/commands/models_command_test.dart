import 'package:dart_ment/src/command_runner.dart';
import 'package:dart_ment/src/commands/models_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('ModelsCommand', () {
    late Logger logger;
    late DartMentCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      commandRunner = DartMentCommandRunner(logger: logger);
    });

    test('can be instantiated', () {
      expect(ModelsCommand(logger: logger), isNotNull);
    });

    test('has correct name', () {
      final command = ModelsCommand(logger: logger);
      expect(command.name, equals('models'));
    });

    test('has correct description', () {
      final command = ModelsCommand(logger: logger);
      expect(
        command.description,
        equals('List and select AI models for dart_ment.'),
      );
    });

    test('handles missing API key', () async {
      when(() => logger.err(any())).thenReturn(null);

      final result = await commandRunner.run(['models', '--list']);

      expect(result, equals(ExitCode.config.code));
      verify(
        () => logger.err(
          any(that: contains('Gemini API key not found')),
        ),
      ).called(1);
    });
  });
}
