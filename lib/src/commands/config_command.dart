import 'package:args/command_runner.dart';
import 'package:dart_ment/src/config/config_manager.dart';
import 'package:dart_ment/src/models/ai_models.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template config_command}
/// `ment config` command to manage dart_ment configuration.
/// {@endtemplate}
class ConfigCommand extends Command<int> {
  /// {@macro config_command}
  ConfigCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addCommand('show')
      ..addCommand('set')
      ..addCommand('path');
  }

  final Logger _logger;

  @override
  String get description => 'Manage dart_ment configuration.';

  @override
  String get name => 'config';

  @override
  Future<int> run() async {
    final subcommand = argResults?.command?.name;
    final configManager = ConfigManager();
    await configManager.initialize();

    switch (subcommand) {
      case 'show':
        return _showConfig(configManager);
      case 'set':
        return _setConfig(configManager);
      case 'path':
        return _showPath(configManager);
      default:
        _logger.info(usage);
        return ExitCode.usage.code;
    }
  }

  Future<int> _showConfig(ConfigManager configManager) async {
    _logger.info('Configuration directory: ${configManager.configPath}');
    _logger.info('');

    final config = await configManager.loadConfig();
    _logger.info('Current configuration:');
    _printConfig(config, indent: 2);

    _logger.info('');
    _logger.info(
      'Current model: ${config['model'] ?? 'gemini-1.5-flash (default)'}',
    );
    _logger.info('');
    _logger.info('To list and select models, use: ment models');
    _logger
        .info('To set a model directly, use: ment config set model <model-id>');

    return ExitCode.success.code;
  }

  Future<int> _setConfig(ConfigManager configManager) async {
    final args = argResults?.command?.rest ?? [];

    if (args.length != 2) {
      _logger.err('Usage: ment config set <key> <value>');
      _logger.err('Example: ment config set model gemini-1.5-pro');
      return ExitCode.usage.code;
    }

    final key = args[0];
    final value = args[1];

    // Validate model selection
    if (key == 'model') {
      final model = AIModel.fromId(value);
      if (model == null || !model.isSupported) {
        _logger.err('Invalid model: $value');
        _logger.info('Available models:');
        for (final m in AIModel.availableModels.where((m) => m.isSupported)) {
          _logger.info('  - ${m.id}');
        }
        return ExitCode.config.code;
      }
    }

    await configManager.updateConfig(key, value);
    _logger.success('Configuration updated: $key = $value');

    return ExitCode.success.code;
  }

  int _showPath(ConfigManager configManager) {
    _logger.info('Configuration directory: ${configManager.configPath}');
    _logger.info('Configuration file: ${configManager.configFile.path}');
    _logger.info('API keys file: ${configManager.apiKeysFile.path}');
    return ExitCode.success.code;
  }

  void _printConfig(Map<String, dynamic> config, {int indent = 0}) {
    final indentStr = ' ' * indent;

    config.forEach((key, value) {
      if (value is Map) {
        _logger.info('$indentStr$key:');
        _printConfig(value as Map<String, dynamic>, indent: indent + 2);
      } else if (value is List) {
        _logger.info('$indentStr$key:');
        for (final item in value) {
          _logger.info('$indentStr  - $item');
        }
      } else {
        _logger.info('$indentStr$key: $value');
      }
    });
  }
}
