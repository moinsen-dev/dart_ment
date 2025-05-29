import 'dart:convert';
import 'dart:io' show Platform;

import 'package:args/command_runner.dart';
import 'package:dart_ment/src/config/config_manager.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';

/// Simple model class to replace GeminiModel
class _ModelInfo {
  _ModelInfo({
    required this.name,
    this.displayName,
    this.version,
    this.inputTokenLimit,
    this.outputTokenLimit,
    this.supportedGenerationMethods,
  });

  factory _ModelInfo.fromJson(Map<String, dynamic> json) {
    return _ModelInfo(
      name: json['name'] as String,
      displayName: json['displayName'] as String?,
      version: json['version'] as String?,
      inputTokenLimit: json['inputTokenLimit'] as int?,
      outputTokenLimit: json['outputTokenLimit'] as int?,
      supportedGenerationMethods:
          (json['supportedGenerationMethods'] as List<dynamic>?)
              ?.cast<String>(),
    );
  }

  final String name;
  final String? displayName;
  final String? version;
  final int? inputTokenLimit;
  final int? outputTokenLimit;
  final List<String>? supportedGenerationMethods;
}

/// {@template models_command}
/// `ment models` command to list and select AI models.
/// {@endtemplate}
class ModelsCommand extends Command<int> {
  /// {@macro models_command}
  ModelsCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addFlag(
        'list',
        abbr: 'l',
        help: 'List all available models',
        negatable: false,
      )
      ..addFlag(
        'select',
        abbr: 's',
        help: 'Select a model interactively',
        negatable: false,
      )
      ..addOption(
        'set',
        help: 'Set a specific model by ID',
        valueHelp: 'model-id',
      );
  }

  final Logger _logger;

  @override
  String get description => 'List and select AI models for dart_ment.';

  @override
  String get name => 'models';

  @override
  Future<int> run() async {
    final configManager = ConfigManager();
    await configManager.initialize();

    // Get API key
    final apiKeys = await configManager.loadApiKeys();
    final apiKey =
        apiKeys['gemini_api_key'] ?? Platform.environment['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      _logger.err(
        'Gemini API key not found. Please set it using:\n'
        '  1. ment config set gemini_api_key <your-key>\n'
        '  2. Or set GEMINI_API_KEY environment variable',
      );
      return ExitCode.config.code;
    }

    // Store API key for use in HTTP calls
    _apiKey = apiKey;

    // Handle different options
    final showList = argResults?['list'] as bool? ?? false;
    final selectMode = argResults?['select'] as bool? ?? false;
    final setModel = argResults?['set'] as String?;

    if (setModel != null) {
      return _setModel(configManager, setModel);
    } else if (selectMode) {
      return _selectModelInteractively(configManager);
    } else if (showList || (!showList && !selectMode && setModel == null)) {
      return _listModels(configManager);
    }

    return ExitCode.success.code;
  }

  late final String _apiKey;

  /// Fetch models from Gemini API
  Future<List<_ModelInfo>> _fetchModels() async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models',
    ).replace(queryParameters: {'key': _apiKey});

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch models: ${response.statusCode} - ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final modelsJson = data['models'] as List<dynamic>?;

    if (modelsJson == null) {
      return [];
    }

    return modelsJson
        .map((json) => _ModelInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> _listModels(ConfigManager configManager) async {
    final progress = _logger.progress(
      'Fetching available models from Gemini API',
    );

    try {
      final models = await _fetchModels();
      progress.complete('Found ${models.length} available models');

      if (models.isEmpty) {
        _logger.warn('No models available');
        return ExitCode.success.code;
      }

      // Get current model from config
      final config = await configManager.loadConfig();
      final currentModel = config['model'] as String?;

      // Filter and prepare model data
      final modelData = <Map<String, String>>[];
      for (final model in models) {
        final modelId = model.name.replaceAll('models/', '');
        final displayName = model.displayName ?? modelId;

        // Skip non-generative models
        if (model.supportedGenerationMethods?.contains('generateContent') !=
            true) {
          continue;
        }

        final isSelected =
            modelId == currentModel ||
            model.name == currentModel ||
            model.name == 'models/$currentModel';

        modelData.add({
          'selected': isSelected ? '✓' : ' ',
          'model': modelId,
          'name': displayName,
          'version': model.version ?? 'N/A',
          'input': _formatTokenLimit(model.inputTokenLimit),
          'output': _formatTokenLimit(model.outputTokenLimit),
        });
      }

      if (modelData.isEmpty) {
        _logger.warn('No generative models available');
        return ExitCode.success.code;
      }

      // Calculate column widths
      final colWidths = {
        'selected': 3,
        'model': _maxLength(modelData, 'model', 'Model ID'),
        'name': _maxLength(modelData, 'name', 'Display Name'),
        'version': _maxLength(modelData, 'version', 'Version'),
        'input': _maxLength(modelData, 'input', 'Input Tokens'),
        'output': _maxLength(modelData, 'output', 'Output Tokens'),
      };

      _logger.info('');
      _logger.info('Available Gemini Models for Content Generation:');
      _logger.info('');

      // Print header
      _printTableRow(
        {
          'selected': '',
          'model': 'Model ID',
          'name': 'Display Name',
          'version': 'Version',
          'input': 'Input Tokens',
          'output': 'Output Tokens',
        },
        colWidths,
        isHeader: true,
      );

      _printTableSeparator(colWidths);

      // Print models
      for (final model in modelData) {
        _printTableRow(model, colWidths);
      }

      _logger.info('');
      _logger.info(
        'Current model: ${lightCyan.wrap(currentModel ?? 'gemini-1.5-flash')} '
        '${currentModel != null && modelData.any((m) => m['model'] == currentModel) ? '✓' : '(not in list)'}',
      );
      _logger.info('');
      _logger.info('To select a model:');
      _logger.info(
        '  • Use: ${lightCyan.wrap('ment models --set <model-id>')}',
      );
      _logger.info(
        '  • Or:  ${lightCyan.wrap('ment models --select')} for interactive selection',
      );

      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to fetch models');
      _logger.err('Error: $e');
      return ExitCode.software.code;
    }
  }

  Future<int> _selectModelInteractively(ConfigManager configManager) async {
    final progress = _logger.progress(
      'Fetching available models from Gemini API',
    );

    try {
      final models = await _fetchModels();
      progress.complete('Found ${models.length} available models');

      if (models.isEmpty) {
        _logger.warn('No models available');
        return ExitCode.success.code;
      }

      // Filter to only generative models
      final generativeModels = models
          .where(
            (m) =>
                m.name.contains('gemini') &&
                (m.supportedGenerationMethods?.contains('generateContent') ??
                    false),
          )
          .toList();

      if (generativeModels.isEmpty) {
        _logger.warn('No generative models available');
        return ExitCode.success.code;
      }

      // Get current model from config
      final config = await configManager.loadConfig();
      final currentModel = config['model'] as String?;

      // Create choices for selection with better formatting
      final choices = <String>[];
      final modelMap = <String, _ModelInfo>{};

      for (final model in generativeModels) {
        final modelId = model.name.replaceAll('models/', '');
        final displayName = model.displayName ?? modelId;
        final inputTokens = _formatTokenLimit(model.inputTokenLimit);
        final outputTokens = _formatTokenLimit(model.outputTokenLimit);
        final version = model.version ?? 'N/A';

        final isCurrentModel = modelId == currentModel;
        final marker = isCurrentModel ? ' ✓' : '';

        final choice =
            '$displayName$marker\n'
            '  └─ ID: $modelId | v$version | '
            'Input: $inputTokens | Output: $outputTokens';

        choices.add(choice);
        modelMap[choice] = model;
      }

      // Find default selection (current model or first)
      var defaultChoice = choices.first;
      for (var i = 0; i < generativeModels.length; i++) {
        final modelId = generativeModels[i].name.replaceAll('models/', '');
        if (modelId == currentModel) {
          defaultChoice = choices[i];
          break;
        }
      }

      _logger.info('\nSelect a model for dart_ment:');
      _logger.info('(Use ↑/↓ arrows to navigate, Enter to select)\n');

      final selection = _logger.chooseOne(
        '',
        choices: choices,
        defaultValue: defaultChoice,
      );

      final selectedModel = modelMap[selection];
      if (selectedModel == null) {
        _logger.err('Invalid model selected');
        return ExitCode.software.code;
      }

      final modelId = selectedModel.name.replaceAll('models/', '');
      if (modelId.isEmpty) {
        _logger.err('Invalid model selected');
        return ExitCode.software.code;
      }

      // Save to config
      await configManager.updateConfig('model', modelId);
      _logger.success('Model set to: $modelId');

      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to fetch models');
      _logger.err('Error: $e');
      return ExitCode.software.code;
    }
  }

  Future<int> _setModel(ConfigManager configManager, String modelId) async {
    // Normalize model ID (remove 'models/' prefix if present)
    final normalizedId = modelId.replaceAll('models/', '');

    // Validate model exists
    final progress = _logger.progress('Validating model');

    try {
      final models = await _fetchModels();
      final modelExists = models.any(
        (m) => m.name == 'models/$normalizedId' || m.name == normalizedId,
      );

      if (!modelExists) {
        progress.fail('Model not found: $normalizedId');
        _logger.info('Use "ment models --list" to see available models');
        return ExitCode.config.code;
      }

      progress.complete('Model validated');

      // Save to config
      await configManager.updateConfig('model', normalizedId);
      _logger.success('Model set to: $normalizedId');

      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to validate model');
      _logger.err('Error: $e');
      return ExitCode.software.code;
    }
  }

  /// Format token limit for display
  String _formatTokenLimit(int? limit) {
    if (limit == null) return 'N/A';
    if (limit >= 1000000) {
      return '${(limit / 1000000).toStringAsFixed(1)}M';
    } else if (limit >= 1000) {
      return '${(limit / 1000).toStringAsFixed(0)}K';
    }
    return limit.toString();
  }

  /// Calculate maximum length for a column
  int _maxLength(List<Map<String, String>> data, String key, String header) {
    var maxLen = header.length;
    for (final row in data) {
      final len = row[key]?.length ?? 0;
      if (len > maxLen) maxLen = len;
    }
    return maxLen + 2; // Add padding
  }

  /// Print a table row
  void _printTableRow(
    Map<String, String> row,
    Map<String, int> colWidths, {
    bool isHeader = false,
  }) {
    final parts = <String>[];
    parts.add(row['selected']!.padRight(colWidths['selected']!));
    parts.add(row['model']!.padRight(colWidths['model']!));
    parts.add(row['name']!.padRight(colWidths['name']!));
    parts.add(row['version']!.padRight(colWidths['version']!));
    parts.add(row['input']!.padRight(colWidths['input']!));
    parts.add(row['output']!.padRight(colWidths['output']!));

    final line = parts.join('│ ');
    if (isHeader) {
      _logger.info(darkGray.wrap(line) ?? line);
    } else {
      // Highlight selected model
      if (row['selected'] == '✓') {
        _logger.info(lightGreen.wrap(line) ?? line);
      } else {
        _logger.info(line);
      }
    }
  }

  /// Print table separator
  void _printTableSeparator(Map<String, int> colWidths) {
    final parts = <String>[];
    parts.add('─' * colWidths['selected']!);
    parts.add('─' * colWidths['model']!);
    parts.add('─' * colWidths['name']!);
    parts.add('─' * colWidths['version']!);
    parts.add('─' * colWidths['input']!);
    parts.add('─' * colWidths['output']!);

    _logger.info(darkGray.wrap(parts.join('┼─')) ?? parts.join('┼─'));
  }
}
