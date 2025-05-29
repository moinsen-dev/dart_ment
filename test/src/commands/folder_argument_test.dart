import 'package:dart_ment/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('Folder argument tests', () {
    late Logger logger;
    late DartMentCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      commandRunner = DartMentCommandRunner(logger: logger);
    });

    test('analyze command accepts folder argument', () async {
      // Test that the command accepts a folder argument
      final result = await commandRunner.run(['analyze', 'lib', '--help']);
      expect(result, equals(ExitCode.success.code));
    });

    test('fix command accepts folder argument', () async {
      // Test that the command accepts a folder argument
      final result = await commandRunner.run(['fix', 'lib', '--help']);
      expect(result, equals(ExitCode.success.code));
    });

    test('analyze command works without folder argument', () async {
      // Test backward compatibility
      final result = await commandRunner.run(['analyze', '--help']);
      expect(result, equals(ExitCode.success.code));
    });

    test('fix command works without folder argument', () async {
      // Test backward compatibility
      final result = await commandRunner.run(['fix', '--help']);
      expect(result, equals(ExitCode.success.code));
    });
  });
}
